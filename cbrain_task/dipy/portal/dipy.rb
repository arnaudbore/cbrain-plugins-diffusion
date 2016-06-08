
# A subclass of CbrainTask to launch Dipy.
class CbrainTask::Dipy < PortalTask

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  def self.properties #:nodoc:
    { :use_parallelizer => true }
  end

  def self.default_launch_args #:nodoc:
    {}
  end

  def before_form #:nodoc:
    params = self.params
    ids    = params[:interface_userfile_ids]
    how_man_are_dipy_inputs = DipyInput.where(:id => ids).count
    cb_error "Not all selected files are Dipy Input files.\n" unless ids.size == how_man_are_dipy_inputs
    ""
  end

  def after_form #:nodoc:
    #params = self.params
    #ids    = params[:interface_userfile_ids]
    ""
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

