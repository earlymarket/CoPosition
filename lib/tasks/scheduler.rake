namespace :scheduler do
  desc "Sends activity email and deletes old activities"
  task check_activity: :environment do
    check_activity
    destroy_activities
  end
end

def check_activity
  return unless Time.current.friday?
  User.all.each do |user|
    last = user.checkins.first.created_at if user.checkins.exists?
    next unless last && last < 1.week.ago
    UserMailer.no_activity_email(user).deliver_now
    smooch_message(user)
  end
end

def smooch_message(user)
  convo_api = SmoochApi::ConversationApi.new
  message = SmoochApi::MessagePost.new(role: "appMaker", type: "text", text: "You have not checked in in the last 7 days")
  user.devices.each do |device|
    next unless device.config.custom && (id = device.config.custom["smoochId"])
    begin
      convo_api.post_message(id, message)
    rescue SmoochApi::ApiError => e
      puts "Exception when calling ConversationApi->post_message: #{e}"
    end
  end
end

def destroy_activities
  PublicActivity::Activity.where("created_at < ?", 1.year.ago).destroy_all
  User.all.each do |user|
    activities = PublicActivity::Activity.where(key: "device.update", owner_id: user.id)
    recent = activities.order("created_at DESC").limit(10)
    activities.where("created_at < ?", recent.last.created_at).destroy_all if recent.exists?
  end
end
