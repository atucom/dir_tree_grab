#!/usr/bin/env ruby
#(C) PTJ.2012
#ruby version of dirtree_grab.sh
#script to automatically log into a specified machine with specified local admin creds to create a directory listing and then pull it down to the local box
#winexe-PTH -U 'Administrator%Support' //10.132.78.12 'fsutil fsinfo drives' --uninstall


require 'optparse' #command line options parser
options = {} #hash that hold the options
optparse = OptionParser.new do|opts|
   opts.banner = "Usage: #{$0} [options] ..." #the banner to display at the top
   optparse = OptionParser.new do|opts| #start defining options below
   options[:username] = nil
   opts.on( '-u', '--user USERNAME', 'The SMB User to login as' ) do|user|
     options[:username] = user
   end
   options[:password] = nil
   opts.on( '-p', '--password PASSWORD', 'The SMB Password to login as' ) do|password|
     options[:password] = password
   end
   options[:ipaddr] = nil
   opts.on( '-t', '--target IPADDRESS', 'The remote host to lob everything at' ) do|ipaddr|
     options[:ipaddr] = ipaddr
   end
   # This displays the help screen, all programs are
   # assumed to have this option.
   opts.on( '-h', '--help', 'Display this screen' ) do
     puts opts
   end
 end.parse!(ARGV)

if !options[:username].nil? or !options[:password].nil? or !options[:ipaddr].nil?

smbuser = options[:username]
smbpass = options[:password]
smbip   = options[:ipaddr]
str = `winexe-PTH -U '#{smbuser}%#{smbpass}' //#{smbip} 'fsutil fsinfo drives' --uninstall | grep -a C:`
p "str=#{str}"

p "str.class= #{str.class}"
str1 =  str.to_s.gsub("\\\x00","").gsub("\r","").gsub("\n","").split(":") #cut out the unicode and windows carriage return
p "str1= #{str1}"
str1.each do |i| #for each entry in the array (the drive) do something
	p "Generating dir list on #{smbip}/#{i}"
	`winexe-PTH -U '#{smbuser}%#{smbpass}' //#{smbip} --uninstall 'cmd.exe /c where /R #{i}:\\ * > C:\\windows\\where_#{i}.txt'`
	p "Grabbing dir list of #{smbip}/#{i}"
	`smbclient -U '#{smbuser}%#{smbpass}' //#{smbip}/C$ -c \"prompt; get windows\\where_#{i}.txt\"`
	p "Cleaning up dir list of #{smbip}/#{i}"
	`smbclient -U '#{smbuser}%#{smbpass}' //#{smbip}/C$ -c \"prompt; del windows\\where_#{i}.txt\"`
	File.rename("windows\\where_#{i}.txt", "#{smbip}_#{i}.txt")

	end
	

else
	puts "Specify -u user -p pass and -t IP"
	exit

end
end

#NOTES

