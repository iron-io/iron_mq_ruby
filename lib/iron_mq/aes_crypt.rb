require 'openssl'
require 'base64'

module IronMQ
  class AESCrypt
    METHOD = 'AES-256-CBC'

    def self.encrypt(message, encryption_key)
      iv = self.initialization_vector

      encoded_message =  self.encrypt_data(message, self.key_digest(encryption_key), iv, METHOD)

      Base64.encode64(iv).strip + ':' + Base64.encode64(encoded_message).strip
    end

    def self.decrypt(body, encryption_key)
      iv, message = body.split(':')

      self.decrypt_data(Base64.decode64(message), self.key_digest(encryption_key), Base64.decode64(iv), METHOD)
    end

    def self.key_digest(encryption_key)
      OpenSSL::Digest::SHA256.new(encryption_key).digest
    end

    def self.decrypt_data(encrypted_data, key, iv, cipher_type)
      aes = OpenSSL::Cipher::Cipher.new(cipher_type)
      aes.decrypt
      aes.key = key
      aes.iv = iv if iv != nil

      data = aes.update(encrypted_data) + aes.final

      if data.respond_to? :force_encoding
        data.force_encoding('UTF-8')
      else
        data
      end
    end

    def self.initialization_vector
      OpenSSL::Random.random_bytes(16)
    end

    def self.encrypt_data(data, key, iv, cipher_type)
      aes = OpenSSL::Cipher::Cipher.new(cipher_type)
      aes.encrypt
      aes.key = key
      aes.iv = iv if iv != nil
      aes.update(data) + aes.final
    end
  end
end