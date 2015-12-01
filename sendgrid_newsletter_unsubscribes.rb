# Works with SendGrid Legacy Newsletter
# Gathers newsletter list emails and writes them to a single location
# This will dedup the addresses as they are added.
# API Reference: https://sendgrid.com/docs/API_Reference/Web_API/Legacy_Features/Marketing_Emails_API/index.html
#
# Author: Kyle Kern
# Ruby Version: 2.1.1
# Required gems: httparty, csv, json
# Running script from cli:
# ruby .path_to/sendgrid_newsletter_unsubscribes.rb

require 'httparty'
require 'csv'
require 'json'

class SendGridNewsletterUnsubscribes
  include HTTParty
  base_uri 'https://api.sendgrid.com/api/newsletter/lists'

  attr_reader :options, :newsletter_lists

  def initialize(api_user:, api_key:)
    @options = { query: {api_user: api_user, api_key: api_key} }
  end

  def get_lists
    response = self.class.get("/lists/get.json", options)
    return response unless response.success?
    @newsletter_lists = JSON.parse(response).inject({}) do |list_hash, list|
                      list_hash[list['id']] = list['list'] unless list.empty?
                      list_hash
                   end
  end

  def get_unsubscribed_emails(list_name:)
    options[:query].merge!(list: list_name, unsubscribed: 1)
    response = self.class.get('/email/get.json', options)
    JSON.parse(response)
  end

  def unique_emails_to_CSV(filepath:, list_names:)
    hash_results = {}
    list_names.each do |name|
      puts "\n"
      puts "Writing unsubscribes for #{name}"
      rows = get_unsubscribed_emails(list_name: name)
      next puts "----#{name} has no unsubscribes on it" if rows.empty?
      CSV.open(filepath, "ab") do |csv|
        rows.each do |row| #open json to parse
          csv << [row['email']] unless hash_results[row['email']] # Check to make sure email is unique
          hash_results[row['email']] = true
        end
      end
    end
    puts "-" * 40
    puts "Wrote #{hash_results.count} entries to #{filepath}"
  end
end


puts "Enter SG Username"
sg_user = gets.chomp
puts "Enter SG Password"
sg_pass = gets.chomp

sg = SendGridNewsletterUnsubscribes.new(api_user: sg_user, api_key: sg_pass)
nl_lists = sg.get_lists

abort nl_lists unless sg.instance_variables.include?(:@newsletter_lists)
puts "\n"

puts "Enter 'all' or specific newsletter list ids.\nexample: 13434 82323232 3354343"
puts "-" * 40
nl_lists.each do |list|
  puts list.join("--")
end
lists = gets.chomp

if lists.downcase == 'all'
  list_ids = nl_lists.keys
else
  list_ids = lists.split.map(&:to_i)
end
abort "No list ids specified to gather" if list_ids.empty?

puts "Enter output csv filepath: "
filepath = gets.chomp
abort "No filepath specified" if filepath.empty?
list_names = list_ids.map { |id| nl_lists[id] }
abort "No lists specified" if list_names.empty?
sg.unique_emails_to_CSV(filepath: filepath, list_names: list_names)