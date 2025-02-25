# Copyright © 2011-2019 MUSC Foundation for Research Development~
# All rights reserved.~

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:~

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.~

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following~
# disclaimer in the documentation and/or other materials provided with the distribution.~

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products~
# derived from this software without specific prior written permission.~

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,~
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT~
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL~
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS~
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR~
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.~
require 'rails_helper'

RSpec.describe 'User should be able to archive protocols', js: true do
  let!(:user) do
    create(:identity,
           last_name: "Doe",
           first_name: "John",
           ldap_uid: "johnd",
           email: "johnd@musc.edu",
           password: "p4ssword",
           password_confirmation: "p4ssword",
           approved: true
          )
  end

  fake_login_for_each_test('johnd')

  let!(:project)  { create(:unarchived_project_without_validations, primary_pi: user) }
  let!(:sr)       { create(:service_request_without_validations, protocol: project) }

  before :each do
    visit dashboard_protocol_path(project)
    wait_for_javascript_to_finish
  end

  it 'displays the archive button to the user' do
    expect(page).to have_content 'Archive Project'
  end

  it 'archives the project when the archive button is clicked' do
    expect(project.archived).to eq(false)
    click_button 'Archive Project'
    wait_for_javascript_to_finish
    expect(project.reload.archived).to eq(true)
    expect(page).to have_content 'Unarchive Project'
  end

  it 'unarchives the project when the unarchive button is clicked' do
    click_button 'Archive Project'
    wait_for_javascript_to_finish
    expect(project.reload.archived).to eq(true)
    click_button 'Unarchive Project'
    wait_for_javascript_to_finish
    expect(project.reload.archived).to eq(false)
    expect(page).to have_content 'Archive Project'
  end
end
