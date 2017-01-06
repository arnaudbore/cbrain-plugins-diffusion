
# A subclass of CbrainTask to launch Dipy.
class CbrainTask::DiffDicom < PortalTask

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  def self.properties #:nodoc:
    { :use_parallelizer => true }
  end

  def self.default_launch_args #:nodoc:
    {
      :sigma          => 0,
      :b0_threshold => 0,
      :frf    => "15,4,4",
      :tag    => ""
    }
  end

  def before_form #:nodoc:
    params = self.params
    ids    = params[:interface_userfile_ids]
    how_man_are_dipy_inputs = DipyInput.where(:id => ids).count
    cb_error "Not all selected files are Dipy Input files.\n" unless ids.size == how_man_are_dipy_inputs
    ""
  end

  def is_number? string
    true if Float(string) rescue false
  end

  def is_frf? string
    string.strip!
    vals = string.split(',')
    return false if vals.length != 3

    return vals.all? {|i| is_number?( i ) }
  end

  def after_form #:nodoc:
    params = self.params

    sigma = params[:sigma]
    self.params_errors.add(:sigma, " must be a number.") unless
      sigma.present? && is_number?( sigma )

    b0_threshold = params[:b0_threshold]
    self.params_errors.add(:b0_threshold, " must be a number.") unless
      b0_threshold.present? && is_number?( b0_threshold )

    frf = params[:frf]
    self.params_errors.add(:frf, " must be a comma separated triplet of numbers ex. 15, 4 ,4.") unless
      frf.present? && is_frf?( frf )

    return ""
  end

  def final_task_list #:nodoc:
    ids    = params[:interface_userfile_ids] || []
    mytasklist = []
    description = "\n\n" + (self.description.presence || "")
    ids.each_with_index do |id,c|
      task=self.dup # not .clone, as of Rails 3.1.10
      task.params[:interface_userfile_ids] = [ id ]
      task.description = Userfile.where(:id => id).raw_first_column(:name)[0].to_s +
                         " (#{c+1}/#{ids.size})" + description
      mytasklist << task
    end
    mytasklist
  end

  def untouchable_params_attributes #:nodoc:
    { :output_ids => true }
  end

end
