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

module Dashboard::EpicQueuesHelper

  def format_protocol(protocol)
    "#{protocol.type.capitalize}: #{protocol.id} - #{protocol.short_title}"
  end

  def format_pis(protocol)
    protocol.principal_investigators.map(&:full_name).join(', ')
  end

  def epic_queue_delete_button(epic_queue)
    content_tag(:button,
      raw(content_tag(:span, '', class: 'glyphicon glyphicon-remove', aria: { hidden: 'true' })),
      type: 'button', data: { epic_queue_id: epic_queue.id, permission: 'true' }, class: "btn btn-danger actions-button delete-epic-queue-button")
  end

  def epic_queue_send_button(epic_queue)
    content_tag(
      :a,
      raw(content_tag(:span, '', class: 'glyphicon glyphicon-hand-right')),
      data: { protocol_id: epic_queue.protocol.id, permission: 'true',
              eq_id: epic_queue.id },
      class: 'btn btn-success push-to-epic')
  end

  def format_epic_queue_date(protocol)
    date = protocol.last_epic_push_time
    if date.present?
      date.strftime(t(:epic_queues)[:date_formatter])
    else
      ''
    end
  end

  def format_epic_queue_created_at(epic_queue)
    created_at = epic_queue.created_at
    created_at.strftime(t(:epic_queues)[:date_formatter])
  end

  def format_status(protocol)
    status = protocol.last_epic_push_status
    if status.present?
      "#{status.capitalize}"
    else
      ''
    end
  end
end
