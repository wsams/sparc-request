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

require 'rails_helper'

RSpec.describe 'User edits Service Pricing Map', js: true do
  let_there_be_lane
  fake_login_for_each_test

  before :each do
    @institution     = create(:institution)
    @provider        = create(:provider, parent_id: @institution.id)
    @program         = create(:program, parent_id: @provider.id)
    @service         = create(:service, organization: @program)
    @catalog_manager = create(:catalog_manager, organization_id: @institution.id, identity_id: Identity.where(ldap_uid: 'jug2').first.id,  edit_historic_data: true)
    create(:pricing_setup, organization: @program)
    create(:pricing_map, service_id: @service.id, display_date: Date.today - 1, effective_date: Date.today - 1)
  end

  context 'on a Service' do
    context 'and the user edits the pricing map dates' do
      before :each do
        visit catalog_manager_catalog_index_path
        wait_for_javascript_to_finish
        find("#institution-#{@institution.id} .glyphicon").click
        find("#provider-#{@provider.id} .glyphicon").click
        find("#program-#{@program.id} .glyphicon").click
        wait_for_javascript_to_finish
        find('a span', text: @service.name).click
        wait_for_javascript_to_finish

        click_link 'Pricing'
        wait_for_javascript_to_finish
      end

      it 'should edit display date and effective date' do
        find('.edit_pricing_map_link').click
        wait_for_javascript_to_finish

        find('#pricing_map_display_date').click
        find('td.today').click

        find('#pricing_map_effective_date').click
        find('td.today').click

        click_button 'Save'
        wait_for_javascript_to_finish

        @service.reload
        expect(@service.pricing_maps.first.display_date).to eq(Date.today)
        expect(@service.pricing_maps.first.effective_date).to eq(Date.today)
      end

      it 'should throw error if the effective date is after display date' do
        find('.edit_pricing_map_link').click
        wait_for_javascript_to_finish

        find('#pricing_map_display_date').click
        find('td.today').click

        click_button 'Save'
        wait_for_javascript_to_finish

        expect(page).to have_content('Effective date must be the same, or later than display date.')
      end

      it 'should disable display date and effective date if the catalog manager cannot edit historic data' do
        @catalog_manager.update_attributes(edit_historic_data: false)
        find('.edit_pricing_map_link').click
        wait_for_javascript_to_finish

        find('#pricing_map_display_date').click
        find('#pricing_map_effective_date').click

        expect(find_by_id('pricing_map_display_date')).to be_disabled
        expect(find_by_id('pricing_map_effective_date')).to be_disabled
      end

    end
  end
end
