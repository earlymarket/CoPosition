module DevicesHelper
  def devices_last_checkin(device)
    if device.checkins.exists?
      message = "<p>Last reported in #{device.checkins.last.address}</p>"
    else
      message = "<p>No Checkins found</p>"
    end
    message.html_safe
  end

  def devices_delay_icon(value)
    if value
      value = '<i class="material-icons">hourglass_full</i>'
    else
      value = '<i class="material-icons">hourglass_empty</i>'
    end
    value.html_safe
  end
end
