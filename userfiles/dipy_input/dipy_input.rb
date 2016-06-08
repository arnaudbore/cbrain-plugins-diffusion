
#
# CBRAIN Project
#
# Copyright (C) 2008-2012
# The Royal Institution for the Advancement of Learning
# McGill University
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# A FileCollection to model a simple DIPY input: a triplet of files
# in a directory, where one is a NIfTI file, one a bval and one a bvec
class DipyInput < FileCollection

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  def self.pretty_type #:nodoc:
    "DIPY Input"
  end

  # Returns the basename of the NIfTI file found in the directory
  def get_nii_basename #:nodoc:

    basenames = self.list_files(".", :file).map { |f| f.name.sub(/.*\//, "") }
    cb_error "DIPY input must contain exactly 3 files: a NIfTI file, a bval and a bvec" if basenames.count != 3
    cb_error "DIPY input doesn't contain a 'bval' file?" unless basenames.include? "bval"
    cb_error "DIPY input doesn't contain a 'bvec' file?" unless basenames.include? "bvec"
    basenames.reject! { |f| f == 'bval' || f == 'bvec' }

    return basenames[0] # no other validation done for the moment
  end

end

