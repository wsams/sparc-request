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

RSpec.describe CatalogManager::SuperUsersController, type: :controller do

  before :each do
    @identity = create(:identity, catalog_overlord: true)
    @organization_id = create(:provider).id
    log_in_catalog_manager_identity(obj: @identity)
  end

  describe '#create' do
    it 'should create a Super User' do
      post :create,
        params: { super_user: { identity_id: @identity.id, organization_id: @organization_id } },
        xhr: true

      expect(SuperUser.count).to eq(1)
    end
  end

  describe '#destroy' do
    it 'should delete an existing Super User' do
      cm = create(:super_user, identity_id: @identity.id, organization_id: @organization_id)
      delete :destroy,
        params: { super_user: { identity_id: @identity.id, organization_id: @organization_id } },
        xhr: true

      expect(SuperUser.count).to eq(0)
    end
  end

  describe '#update' do
    it 'should update access_empty_protocols to true' do
      su = create(:super_user, identity_id: @identity.id, organization_id: @organization_id, access_empty_protocols: false)
      put :update,
        params: { super_user: { identity_id: @identity.id, organization_id: @organization_id, access_empty_protocols: 'true' } },
        xhr: true

      expect(su.reload.access_empty_protocols).to eq(true)
    end

    it 'should update access_empty_protocols to false' do
      su = create(:super_user, identity_id: @identity.id, organization_id: @organization_id, access_empty_protocols: true)
      put :update,
        params: { super_user: { identity_id: @identity.id, organization_id: @organization_id, access_empty_protocols: 'false' } },
        xhr: true

      expect(su.reload.access_empty_protocols).to eq(false)
    end
  end

end
