require 'openssl'

module Lightrail
  class Encryptor
    class InvalidMessage < StandardError; end
    OpenSSLCipherError = OpenSSL::Cipher.const_defined?(:CipherError) ? OpenSSL::Cipher::CipherError : OpenSSL::CipherError

    attr_accessor :addon_secret

    def initialize(secret)
      @addon_secret = secret
    end

    def encrypt(msg, initvec = nil)
      msg       = msg.to_s
      cipher    = new_cipher
      initvec   = decode64(initvec) if initvec
      initvec ||= cipher.random_iv

      cipher.encrypt
      cipher.key = decode64(addon_secret)
      cipher.iv  = initvec

      encrypted  = cipher.update(msg)
      encrypted << cipher.final

      [ encrypted, initvec ].
        map { |bytes| encode64(bytes) }.
        join("--")
    end

    def decrypt(encrypted_message)
      cipher = new_cipher
      encrypted_data, iv = encrypted_message.split("--").map { |v| decode64(v) }

      cipher.decrypt
      cipher.key = decode64(addon_secret)
      cipher.iv  = iv

      decrypted_data = cipher.update(encrypted_data)
      decrypted_data << cipher.final

      decrypted_data
    rescue OpenSSLCipherError, TypeError
      raise InvalidMessage
    end

    private

    def decode64(s)
      ActiveSupport::Base64.decode64(s)
    end

    def encode64(s)
      ActiveSupport::Base64.encode64s(s)
    end

    def new_cipher
      OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    end
  end
end