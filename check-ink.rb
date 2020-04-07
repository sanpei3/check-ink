
require 'rubygems'
require 'time'
require 'action_mailer'
require 'mail-iso-2022-jp'

require 'mechanize'

require 'nokogiri'
require 'pp'

old_file = "/tmp/inklevel.old"
new_file = "/tmp/inklevel.new"

exe = '/usr/local/bin/ink -p bjnp'
$debug = 0

result = ""
if ($debug == 1)
  File.open("20180915","r:UTF-8") do |body|
    body.each_line do |oneline|
      result = result + oneline.to_s
    end
  end
else
  result = `#{exe}`
end

if (/No printer found./ =~ result)
  exit
end
#pp html

require 'digest/md5'
ActionMailer::Base.smtp_settings = {
	:enable_starttls_auto => false,
#	:openssl_verify_modo => none
}

class HogeMailer < ActionMailer::Base
  def hogeMessage(toAddress, mySubject, myBody)
    mail(:from => 'sanpei@sanpei.org',
         :to => toAddress,
         :subject => mySubject,
         :body => myBody,
         :charset => "iso-2022-jp",
	 :enable_starttls_auto => false,
	 :openssl_verify_mode => "none"
        )
  end
end

if (!File.exist?(old_file))
  File.new(old_file, "w")
end

File.open(new_file, "w") do |io|
  io.write result
end
diff_result = `/usr/bin/diff -u #{old_file} #{new_file} `.force_encoding("UTF-8")
diff = ""
diff_result.each_line do |oneline|
  if (oneline =~ /^\+/ ||oneline =~ /^\-/)
    #puts oneline
    oneline = oneline.gsub(/<\s+>/, "")
    diff = diff + oneline
  end
end
if (diff != "")
  diff = diff.gsub(/Yellow/,"Yellow\t\tBCI-326Y")
  diff = diff.gsub(/Magenta/,"Magenta\t\tBCI-326M")
  diff = diff.gsub(/Photoblack/,"Photoblack\tBCI-326BK")
  diff = diff.gsub(/Cyan/,"Cyan\t\tBCI-326C")
  diff = diff.gsub(/Black/,"Black\t\tBCI-325PGBK")
  diff = diff.gsub(/Photogrey/,"Photogrey\tBCI-326GY")
  FileUtils.cp(new_file, old_file)
#  puts "mismatch Windsor"
#  puts diff
  mail_address = "sanpei@sanpei.org"
  
  subject = "find changes in inklevel"
  
  mail = HogeMailer.hogeMessage(mail_address, subject, diff)
  mail.deliver_now
end


# 1. download web site
# 2. parse smenuBox
# 3. write smenuBox
# 4. compare md5
# 5. diff files old and new
# 6. get only new line >
# 7. move new smenuBox to old one
# 8. send email
