#!/usr/bin/env ruby

require 'xmlrpc/client'
require 'pp'

class Freshmeat
  def call(meth, args)
    # make sure we're connect to freshmeat
    @rpc = XMLRPC::Client.new('freshmeat.net', '/xmlrpc', 80) unless @rpc
    pp meth, args
    @rpc.call(meth, args)
  end

  def login(user, pass)
    # log in
    ret = call('login', {'username' => user, 'password' => pass})

    pp ret

    # convert lifetime to integer
    ret['Lifetime'] = ret['Lifetime'].to_i

    # cache user/pass and update expired time/session id
    @user, @pass = user, pass
    @expire_time = Time.now.to_i + ret['Lifetime']
    @sid = ret['SID']

    # return hash
    ret
  end

  def check_login
    # check username and password
    raise "Missing username" unless @user
    raise "Missing password" unless @pass

    # if we're timed out, then kill the session
    # (always make sure we're logged in)
    login(@user, @pass) if @expire_time < Time.now.to_i
  end

  private :call, :check_login

  def initialize(user = nil, pass = nil)
    @expire_time = 0
    login(user, pass) if user && pass
  end

  def licenses # Fetch all available licenses
    call('fetch_available_licenses')
  end

  def release_foci # Fetch all available release focus types
    call('fetch_available_release_foci')
  end

  def branches(project_name) # Fetch all branch names and IDs for a given project 
    check_login
    call('fetch_branch_list', {'SID' => @sid, 'project_name' => project_name})
  end

  def projects # Fetch all projects assigned to logged in user
    check_login
    call('fetch_project_list', {'SID' => @sid})
  end

  def fetch_release(project, branch, version) # Fetch data from a pending release submission
    check_login
    call('fetch_release', {'SID' => @sid, 'project_name' => project, 'branch_name' => branch, 'version' => version})
  end

  def logout # End an XML-RPC session
    check_login
    call('logout', {'SID' => @sid}).has_key?('OK')
    @user, @pass, @rpc = nil, nil, nil
  end

  def publish_release(project, branch, version, changes, release_focus, hide_from_homepage = false, license = nil, urls = nil)
    # build argument list
    args ={
      'SID' => @sid,
      'project_name' => project,
      'branch_name' => branch,
      'version' => branch,
      'changes' => changes,
      'release_focus' => release_focus,
      'hide_from_homepage' => hide_from_homepage ? 'Y' : 'N',
    } 

    # add optional arguments
    args['license'] = license if license
    args.update(urls) if urls

    # run command
    check_login
    call('publish_release', args).has_key?('OK')
  end

  def withdraw_release(project, branch, version)
    check_login
    call('withdraw_release', {
      'SID' => @sid, 
      'project_name' => project,
      'branch_name' => branch,
      'version' => version
    }).has_key?('OK')
  end
end

