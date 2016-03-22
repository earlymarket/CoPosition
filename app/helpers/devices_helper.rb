module DevicesHelper
  def devices_last_checkin(device)
    if device.checkins.exists?
      "<p>Last reported in #{device.checkins.last.address}</p>".html_safe
    else
      "<p>No Checkins found</p>".html_safe
    end
  end

  def devices_delay_icon(value)
    if value
      '<i class="material-icons">hourglass_full</i>'.html_safe
    else
      '<i class="material-icons">hourglass_empty</i>'.html_safe
    end
  end

  def devices_published_icon(device)
    if device.published?
      '<i class="material-icons">visibility</i>'.html_safe
    else
      '<i class="material-icons">visibility_off</i>'.html_safe
    end
  end

  def devices_published_link(device)
    if device.published?
      url = url_for(action: 'publish', controller: 'users/devices', id: device, user_id: device.user_id, only_path: false)
      "<a href='#{url}''>Share published link</a>".html_safe
    else
      "".html_safe
    end
  end
end
