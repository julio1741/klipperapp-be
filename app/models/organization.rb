class Organization < ApplicationRecord
  include Filterable

  after_save :set_slug_from_name
  after_save :generate_qr_code_base64

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  private

  def set_slug_from_name
    update_column(:slug, name.to_s.parameterize)
  end

  def generate_qr_code_base64
    host = ENV['APP_HOST'] || 'https://example.com'
    url = "#{host}/#{slug}"
    qrcode = RQRCode::QRCode.new(url)
    png = qrcode.as_png(size: 300)
    base64 = Base64.strict_encode64(png.to_s)
    update_column(:qr_code, base64)
  end
end
