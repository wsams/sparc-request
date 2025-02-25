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

desc 'Merge an old service into a new service (example only).'

task :merge_services, [:services_list] => :environment do |t, args|
  skipped_services = CSV.open("tmp/skipped_merged_services_#{Time.now.strftime('%m%d%Y%T')}.csv", "wb")
  ActiveRecord::Base.transaction do
    # "Merge" old services into corresponding new ones.
    CSV.foreach(args[:services_list], headers: true) do |row|
      begin
        merge_service(row['Old Service ID'].strip, row['New Service ID'].strip)
      rescue
        skipped_services << row
      end
    end

    # 68 no longer a process_ssrs. Fix organization_id on SSR's belonging to 68.
    ssrs = []
    SubServiceRequest.where(organization_id: 68).each do |ssr|
      if ssr.line_items.empty?
        ssr.destroy
        next
      end
      # Pick an arbitrary service, and make
      # ssr belong to the service's process_ssrs_parent.
      process_ssrs_parent = ssr.line_items.first.service.organization.process_ssrs_parent

      if process_ssrs_parent
        ssr.update!(organization_id: process_ssrs_parent.id)
      end

      ssr.reload
      ssrs << ssr
    end

    # Great. Now shuffle LineItems between SSR's as needed
    ssrs_count = ssrs.length
    ssrs_processed = 0
    ssrs.each do |ssr|
      ssrs_processed += 1
      puts "Processing SSR #{ssrs_processed}/#{ssrs_count}"

      # Make sure each LineItem in proper SSR.
      ssr.line_items.each do |li|
        process_ssrs_parent = li.service.organization.process_ssrs_parent

        # If li shouldn't belong to ssr.
        if process_ssrs_parent.id != ssr.organization_id
          # Create/find SubServiceRequest for li.
          dest_ssr = ssr.service_request.sub_service_requests.
            where(status: ssr.status).
            find_or_create_by(organization_id: process_ssrs_parent.id)

          # Is this probably a newly created SSR?
          if !dest_ssr.ssr_id && !dest_ssr.service_requester_id && !dest_ssr.owner_id
            # Move over old SSR attributes.
            old_attributes = ssr.attributes
            # ! needed, since only it will return the _other_ attributes.
            copy_over_attributes = old_attributes.
              slice!(*%w(id ssr_id organization_id org_tree_display status))
            dest_ssr.assign_attributes(copy_over_attributes, without_protection: true)
            dest_ssr.save(validate: false)
            dest_ssr.update_org_tree
            ssr.service_request.ensure_ssr_ids
          end

          # Move li.
          li.update!(sub_service_request_id: dest_ssr.id)
        end
      end # ssr.line_items.each
    end # ssrs.each
  end # ActiveRecord::Base.transaction
end # task

def merge_service(old_service_id, new_service_id)
  old_service = Service.find(old_service_id)
  new_service = Service.find(new_service_id)
  dest_org_process_ssrs = new_service.organization.process_ssrs_parent
  puts "Merging Service #{old_service.id} into #{new_service.id} belonging to Org ##{dest_org_process_ssrs.id}"

  [LineItem, ServiceProvider].each do |model|
    model.where(service_id: old_service_id).each do |obj|
      obj.update!(service_id: new_service_id)
    end
  end

  old_service.destroy
end
