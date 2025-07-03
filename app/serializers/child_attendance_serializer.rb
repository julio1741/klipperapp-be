class ChildAttendanceSerializer < ActiveModel::Serializer
  attributes :id, :status, :date, :time, :discount, :extra_discount,
    :user_amount, :organization_amount, :total_amount, :tip_amount,
    :start_attendance_at, :end_attendance_at, :attended_by, :branch_id, :organization_id,
    :profile_id, :payment_methodm, :created_at, :updated_at

  belongs_to :attended_by_user, serializer: UserSerializer
  belongs_to :profile
  has_many :services
end
