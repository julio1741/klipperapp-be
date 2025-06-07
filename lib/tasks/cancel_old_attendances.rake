namespace :attendance do
  desc "Cancel attendances pending from previous days"
  task cancel_old_pending: :environment do
    Attendance.cancel_old_pending_attendances
    puts "Old pending attendances have been canceled."
  end
end
