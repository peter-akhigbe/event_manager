# frozen_string_literal: true

require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip) # rubocop:disable Metrics/MethodLength
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") { |file| file.puts form_letter }
end

def clean_phone_number(phone_number)
  phone_number.to_s.gsub!(/[^0-9]/, "")

  if phone_number.length == 11 && phone_number[0] == "1"
    phone_number[1..10]
  elsif phone_number.length == 10
    phone_number
  else
    "Invalid Phone Number"
  end
end

def get_hour(date_string)
  time_format = "%m/%d/%y %H:%M"
  time = DateTime.strptime(date_string, time_format)
  time.hour
end

def get_day(date_string)
  time_format = "%m/%d/%y %H:%M"
  time = DateTime.strptime(date_string, time_format)
  time.wday
end

def most_frequent_item(arr)
  result = []

  counts = Hash.new(0)
  arr.each { |item| counts[item] += 1 }

  max = counts.values.max
  counts.select { |key, value| result.push(key) if value == max }

  result
end

# ---------- All methods are delcared above this comment ----------

puts "EventManager initialized."

contents =
  CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

hours_array = []
days_array = []

days_of_week = {
  0 => "sunday",
  1 => "monday",
  2 => "tuesday",
  3 => "wednesday",
  4 => "thursday",
  5 => "friday",
  6 => "saturday"
}

contents.each do |row|
  hour = get_hour(row[:regdate])
  hours_array.push("#{hour}:00")

  day = get_day(row[:regdate])
  days_array.push(days_of_week[day])

  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

p "The most frequent hour of the day is: #{most_frequent_item(hours_array).join(", ")}."
p "The most common day of the week is: #{most_frequent_item(days_array).join(", ")}."
