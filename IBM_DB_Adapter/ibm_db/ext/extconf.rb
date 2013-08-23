#!/usr/bin/env ruby

# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006 - 2012                            |
# +----------------------------------------------------------------------+

WIN = RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/

# use ENV['IBM_DB_HOME'] or latest db2 you can find
IBM_DB_HOME = ENV['IBM_DB_HOME']

machine_bits = ['ibm'].pack('p').size * 8

is64Bit = true

module Kernel
  def suppress_warnings
    origVerbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = origVerbosity
    return result
  end
end

if machine_bits == 64
  is64Bit = true
  puts "Detected 64-bit Ruby\n "
else
  is64Bit = false
  puts "Detected 32-bit Ruby\n "
end

if(IBM_DB_HOME == nil || IBM_DB_HOME == '')
  IBM_DB_INCLUDE = ENV['IBM_DB_INCLUDE']
  IBM_DB_LIB = ENV['IBM_DB_LIB']
  
  if( ( (IBM_DB_INCLUDE.nil?) || (IBM_DB_LIB.nil?) ) ||
      ( IBM_DB_INCLUDE == '' || IBM_DB_LIB == '' )
	)
    puts "Environment variable IBM_DB_HOME is not set. Set it to your DB2/IBM_Data_Server_Driver installation directory and retry gem install.\n "
    exit 1
  end
else
  IBM_DB_INCLUDE = "#{IBM_DB_HOME}/include"
  
  if(is64Bit)
    IBM_DB_LIB="#{IBM_DB_HOME}/lib64"
  else
    IBM_DB_LIB="#{IBM_DB_HOME}/lib32"
  end
end

if( !(File.directory?(IBM_DB_LIB)) )
  suppress_warnings{IBM_DB_LIB = "#{IBM_DB_HOME}/lib"}
  if( !(File.directory?(IBM_DB_LIB)) )
    puts "Cannot find #{IBM_DB_LIB} directory. Check if you have set the IBM_DB_HOME environment variable's value correctly\n "
	exit 1
  end
  notifyString  = "Detected usage of IBM Data Server Driver package. Ensure you have downloaded "
  
  if(is64Bit)
    notifyString = notifyString + "64-bit package "
  else
    notifyString = notifyString + "32-bit package "
  end
  notifyString = notifyString + "of IBM_Data_Server_Driver and retry the 'gem install ibm_db' command\n "
  
  puts notifyString
end

if( !(File.directory?(IBM_DB_INCLUDE)) )
  puts " #{IBM_DB_HOME}/include folder not found. Check if you have set the IBM_DB_HOME environment variable's value correctly\n "
  exit 1
end

require 'mkmf'

dir_config('IBM_DB',IBM_DB_INCLUDE,IBM_DB_LIB)

def crash(str)
  printf(" extconf failure: %s\n", str)
  exit 1
end

if( RUBY_VERSION =~ /1.9/)
  create_header('gil_release_version')
  create_header('unicode_support_version')
end

unless (have_library(WIN ? 'db2cli' : 'db2','SQLConnect') or find_library(WIN ? 'db2cli' : 'db2','SQLConnect', IBM_DB_LIB))
  crash(<<EOL)
Unable to locate libdb2.so/a under #{IBM_DB_LIB}

Follow the steps below and retry

Step 1: - Install IBM DB2 Universal Database Server/Client

step 2: - Set the environment variable IBM_DB_HOME as below
        
             (assuming bash shell)
        
             export IBM_DB_HOME=<DB2/IBM_Data_Server_Driver installation directory> #(Eg: export IBM_DB_HOME=/opt/ibm/db2/v10)

step 3: - Retry gem install
        
EOL
end

alias :libpathflag0 :libpathflag
def libpathflag(libpath)
  libpathflag0 + case Config::CONFIG["arch"]
    when /solaris2/
      libpath[0..-2].map {|path| " -R#{path}"}.join
    when /linux/
      libpath[0..-2].map {|path| " -Wl,-rpath,#{path}"}.join
    else
      ""
  end
end

have_header('gil_release_version')
have_header('unicode_support_version')

create_makefile('ibm_db')
