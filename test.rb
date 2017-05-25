require 'minitest/autorun'
require 'resolv'
require 'yaml'
require 'pp'

class TestConfig < Minitest::Test
  REDIRECTS = [301, 302]
  def setup
    @config = YAML::load_file 'redirects.yml'
  end

  def test_redirect_sections
    @config.each do |code, zone|
      assert REDIRECTS.include? code
    end
  end

  def test_each_domain
    @config.each do |section, zone|
      zone.each do |domain, redirect|
        url = get_url(redirect, "")
        refute_nil url, "Invalid YAML config for #{domain}"
        assert resolves_to_lightsaber(domain),
          "DNS for #{domain} isn't setup yet. See README"
      end
    end
  end

  def resolves_to_lightsaber(domain)
    flag = domain === "lightsaber.thatharmansingh.com"
    Resolv::DNS.open do |dns|
      records = dns.getresources domain, Resolv::DNS::Resource::IN::CNAME
      records.each do |record|
        flag||=record.name.to_s === "harman-lightsaber.herokuapp.com"
      end
    end
    flag
  end

  def get_url(domain_object, rel_route)
    if domain_object.is_a? Hash
      return domain_object['root'] + "/" + rel_route
    elsif domain_object.is_a? String
      return domain_object
    end
  end
end