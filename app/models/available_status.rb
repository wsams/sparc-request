# Copyright © 2011-2019 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class AvailableStatus < ApplicationRecord

  audited

  belongs_to :organization

  before_update :sync_editable_status

  scope :selected, -> { where(selected: true) }
  scope :alphabetized, -> { all.sort{ |x, y| x.humanize <=> y.humanize } }

  def disabled_status?
    ["Draft", "Get a Cost Estimate", "Submitted"].include?(self.humanize)
  end

  def self.statuses
    @statuses ||= PermissibleValue.get_hash('status')
  end

  def self.defaults
    @defaults ||= PermissibleValue.get_key_list('status', true)
  end

  def humanize
    AvailableStatus.statuses[self.status]
  end

  def self.types
    self.statuses.keys
  end

  def editable_status
    EditableStatus.find_by(organization_id: organization_id, status: status)
  end

  private

  def sync_editable_status
    if selected_changed? && editable_status
      editable_status.update_attribute(:selected, selected)
    end
  end
end
