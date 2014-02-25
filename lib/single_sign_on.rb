class SingleSignOn
  ACCESSORS = [:nonce, :return_url, :name, :username, :email, :about_me, :external_id]
  FIXNUMS = []
  NONCE_EXPIRY_TIME = 10.minutes

  attr_accessor(*ACCESSORS)
  attr_accessor :sso_secret, :sso_url

  def self.sso_secret
    raise RuntimeError, "sso_secret not implemented on class, be sure to set it on instance"
  end

  def self.sso_url
    raise RuntimeError, "sso_url not implemented on class, be sure to set it on instance"
  end

  def sso_secret
    @sso_secret || self.class.sso_secret
  end

  def sso_url
    @sso_url || self.class.sso_url
  end

  def self.parse(payload, sso_secret = nil)
    sso = new
    sso.sso_secret = sso_secret if sso_secret

    parsed = Rack::Utils.parse_query(payload)
    if sso.sign(parsed["sso"]) != parsed["sig"]
      raise RuntimeError, "Bad signature for payload"
    end

    decoded = Base64.decode64(parsed["sso"])
    decoded_hash = Rack::Utils.parse_query(decoded)

    ACCESSORS.each do |k|
      val = decoded_hash[k.to_s]
      val = val.to_i if FIXNUMS.include? k
      sso.send("#{k}=", val)
    end
    sso
  end

  def sign(payload)
    OpenSSL::HMAC.hexdigest("sha256", sso_secret, payload)
  end


  def to_url(base_url=nil)
    "#{base_url || sso_url}?#{payload}"
  end

  def payload
    payload = Base64.encode64(unsigned_payload)
    "sso=#{CGI::escape(payload)}&sig=#{sign(payload)}"
  end

  def unsigned_payload
    payload = {}
    ACCESSORS.each do |k|
     next unless (val = send k)

     payload[k] = val
    end

    Rack::Utils.build_query(payload)
  end

end
