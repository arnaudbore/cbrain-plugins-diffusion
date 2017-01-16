
# A subclass of CbrainTask::ClusterTask to run the diffusion pipeline using dicom files.
class CbrainTask::DicomDiffusion < ClusterTask

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  include RestartableTask
  include RecoverableTask

  def job_walltime_estimate #:nodoc:
    ids          = params[:interface_userfile_ids] || []
    30.minutes + (40.minutes * ids.size)
  end

  # See the CbrainTask Programmer Guide
  def setup #:nodoc:
    params       = self.params
    ids          = params[:interface_userfile_ids] || []
    inputs       = TarArchive.find(ids)

    # Prep work area
    inputdir     = "Inputs-#{run_number}"
    outputdir    = "Outputs-#{run_number}"
    safe_mkdir(inputdir)
    safe_mkdir(outputdir)

    inputs.each do |userfile|
      userfile.sync_to_cache
      # nii_basename = userfile.get_nii_basename

      # Because the current dipy_simple_pipeline script is not clean with its
      # inputs, we have to create a dummy input structure
      safe_mkdir("#{inputdir}/#{userfile.id}")
      safe_symlink(userfile.cache_full_path, "#{inputdir}/#{userfile.id}/dwi_archive.tar")
    end
    true
  end

  # See the CbrainTask Programmer Guide
  def cluster_commands #:nodoc:
    params       = self.params
    ids          = params[:interface_userfile_ids] || []
    sigma        = params[:sigma]
    tag          = params[:tag]
    b0_threshold = params[:b0_threshold]
    frf          = params[:frf]

    inputs       = TarArchive.find(ids)

    inputdir     = "Inputs-#{run_number}"
    outputdir    = "Outputs-#{run_number}"

    # Build bash commands for each execution
    commands     = [ "SECONDS=0" ] # bash variable SECONDS will count time
    inputs.each do |userfile|
      indir = "#{inputdir}/#{userfile.id}"
      cmdl_params =  "#{indir}/#{userfile.bash_escape} --out_strat absolute --out_dir #{outputdir}/#{userfile.id}/ --tag #{tag} --nlmeans.sigma #{sigma} --csd.frf #{frf} --csd.b0_threshold #{b0_threshold} --csa.b0_threshold #{b0_threshold} --dti.b0_threshold #{b0_threshold}"

      commands << <<-"BASH_COMMANDS"
         echo Executing dipy_dicom_fodf_pipeline_fsl for #{userfile.get_nii_basename.bash_escape}
         dipy_dicom_fodf_pipeline_fsl #{cmdl_params}
         echo Done after $SECONDS seconds
       BASH_COMMANDS
    end

    commands
  end

  # See the CbrainTask Programmer Guide
  def save_results #:nodoc:
    params       = self.params
    ids          = params[:interface_userfile_ids] || []
    inputs       = TarArchive.find(ids)

    #inputdir     = "Inputs-#{run_number}" # not used here
    outputdir    = "Outputs-#{run_number}"

    failed     = 0
    output_ids = []

    inputs.each do |userfile|

      # Check that output is OK.
      if ! File.directory?("#{outputdir}/#{userfile.id}")
        failed += 1
        addlog("Error: not output created for file ID=#{userfile.id}, NAME=#{userfile.name}")
        next
      end

      # Create new output within CBRAIN
      dp_id = self.results_data_provider_id.presence || userfile.data_provider_id
      output = safe_userfile_find_or_new(DipyOutput,
        :name             => "DipyOut-#{self.bname_tid_dashed}-#{self.run_number}",
        :data_provider_id => dp_id,
      )

      # Upload content
      output.cache_copy_from_local_file("#{outputdir}/#{userfile.id}") # uploads the dir's CONTENT
      output.save

      # Provenance information
      self.addlog_to_userfiles_these_created_these(userfile, output)
      #output.addlog("Created with dipy version xyz")

      # File manager elegance: show output as a child of input
      output.move_to_child_of(userfile)

      # Gather IDs of all created outputs
      output_ids << output.id
    end

    # Record output IDs so that task 'show' page can create links
    params[:output_ids] = output_ids

    return false if failed > 0

    true
  end

end
