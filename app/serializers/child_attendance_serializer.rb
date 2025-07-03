class ChildAttendanceSerializer < ActiveModel::Serializer
  attributes :id, :status, :date, :time, :discount, :extra_discount, :user_amount, :organization_amount, :total_amount, :start_attendance_at, :end_attendance_at

  belongs_to :attended_by_user, serializer: UserSerializer
  belongs_to :profile
  has_many :services
end
