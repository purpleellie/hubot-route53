# Configuration:
#   HUBOT_AWS_ACCESS_KEY_ID
#   HUBOT_AWS_SECRET_ACCESS_KEY
#
# Commands:
#   hubot create bucket <name> [<acl settings> <region>] - Returns the list of s3 buckets
#
# Author:
#   Andrew Quitadamo

key = process.env.HUBOT_ROUTE53_ACCESS_KEY_ID
secret = process.env.HUBOT_ROUTE53_SECRET_ACCESS_KEY

aws = require 'aws-sdk'
aws.config.update({accessKeyId: key, secretAccessKey: secret})

route53 = new aws.Route53()

module.exports = (robot) ->
  robot.respond /list hosted zones/i, (msg) ->
    route53.listHostedZones {}, (error, data) ->
      if error?
         msg.send "#{error}"
         return
      hostedZones = data.HostedZones
      for zone in hostedZones
        msg.send "ID: #{zone.Id}\nName: #{zone.Name}\nCaller Reference: #{zone.CallerReference}\nRecord Count: #{zone.ResourceRecordSetCount}"

module.exports = (robot) ->
  robot.respond /list hosted zones by name/i, (msg) ->
    route53.listHostedZones {}, (error, data) ->
      if error?
         msg.send "#{error}"
         return
      hostedZones = data.HostedZones
      for zone in hostedZones
        msg.send "ID: #{zone.Id}\nName: #{zone.Name}\nCaller Reference: #{zone.CallerReference}\nRecord Count: #{zone.ResourceRecordSetCount}"

  robot.respond /create hosted zone ([\w.+\-]+) ([\w.+\-]+)/i, (msg) ->
    callerReference = msg.match[1]
    name = msg.match[2]
    params = 
      CallerReference: callerReference
      Name: name
    route53.createHostedZone params, (error, data) ->
      if error? 
        msg.send "#{error}"
        return
      zone = data.HostedZone
      msg.send "ID: #{zone.Id}\nName: #{zone.Name}\nCaller Reference: #{zone.CallerReference}"

  robot.respond /delete hosted zone ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params =
      Id: id
    route53.deleteHostedZone params, (error, data) ->
      if error?
        msg.send "#{error}"
        return
      msg.send "Hosted zone #{id} was deleted successfully.\n"

  robot.respond /get hosted zone ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params =
      Id: id
    route53.getHostedZone params, (error, data) ->
      if error?
        msg.send "#{error}"
        return
      zone = data.HostedZone
      msg.send "ID: #{zone.Id}\nName: #{zone.Name}\nCaller Reference: #{zone.CallerReference}"

  #TODO: Add more data to message
  robot.respond /list health checks/i, (msg) ->
    route53.listHealthChecks {}, (error, data) ->
      if error?
        msg.send "#{error}"
        return
      checks = data.HealthChecks
      for check in checks
        config = check.HealthCheckConfig
        message = ""
        message += "ID: #{check.Id}\nCaller Reference: #{check.CallerReference}"
        if config.IPAddress
          message += "\nIP Address: #{config.IPAddress}"
        if config.Port
          message += "\nPort: #{config.Port}"
        message += "\nType: #{config.Type}"
        if config.ResourcePath
          message += "\nResource Path: #{config.ResourcePath}"
        if config.FullyQualifiedDomainName
          message += "\nDomain Name: #{config.FullyQualifiedDomainName}"
        if config.SearchString
          message += "\nSearch String #{config.SearchString}"
        if config.RequestInterval
          message += "\nRequestInterval #{config.RequestInterval}"
        if config.FailureThreshold
          message += "\nFailure Threshold: #{config.FailureThreshold}"
        message += "\nVersion: #{check.HealthCheckVersion}"
        msg.send "#{message}"

  robot.respond /list records ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params = 
      HostedZoneId: id
    route53.listResourceRecordSets params, (error, data) ->
      if error?
        msg.send "#{error}"
        return
      records = data.ResourceRecordSets
      for record in records
        message ="Name: #{record.Name}\nRecord Type: #{record.Type}\nTTL: #{record.TTL}"
        for rec in record.ResourceRecords
          message += "\n#{rec.Value}"
        if record.AliasTarget
          message += "\nDNSName: #{record.AliasTarget.DNSName}"
        msg.send "#{message}"

  robot.respond /get health check status ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params =
      HealthCheckId: id
    route53.getHealthCheckStatus params, (error, data) ->
      if error?
        msg.send "#{error}"
        return
      obs = data.HealthCheckObservations
      message = ""
      pauser = setInterval ->
        ob = obs.pop()
        if ob == undefined
          clearInterval pauser
        else
          msg.send "Status: #{ob.StatusReport.Status}\nChecker IP: #{ob.IPAddress}\nTime: #{ob.StatusReport.CheckedTime}" 
      , 700

  robot.respond /get health check ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params =
      HealthCheckId: id
    route53.getHealthCheck params, (error, data) ->
      if error?
        msg.send "#{error}"
        return
      healthCheck = data.HealthCheck
      config = healthCheck.HealthCheckConfig
      message = ""
      message += "ID: #{healthCheck.Id}\nCaller Reference: #{healthCheck.CallerReference}"
      if config.IPAddress
        message += "\nIP Address: #{config.IPAddress}"
      if config.Port
        message += "\nPort: #{config.Port}"
      message += "\nType: #{config.Type}"
      if config.ResourcePath
        message += "\nResource Path: #{config.ResourcePath}"
      if config.FullyQualifiedDomainName
        message += "\nDomain Name: #{config.FullyQualifiedDomainName}"
      if config.SearchString
        message += "\nSearch String #{config.SearchString}"
      if config.RequestInterval
        message += "\nRequestInterval #{config.RequestInterval}"
      if config.FailureThreshold
        message += "\nFailure Threshold: #{config.FailureThreshold}"
      message += "\nVersion: #{healthCheck.HealthCheckVersion}"
      msg.send "#{message}"

  robot.respond /create health check (.*)/i, (msg) ->
    args = msg.match[1].split(" ")
    config = {}
    for i in [0..args.length] by 2
      if args[i] == "-c"
        callerRef = args[i+1]
      if args[i] == "-t"
        type = args[i+1]
        config.Type = args[i+1]
      if args[i] == "-f"
        congig.FailureThreshold = args[i+1]
      if args[i] == "-d"
        config.FullyQualifiedDomainName = args[i+1]
      if args[i] == "-i"
        config.IPAddress = args[i+1]
      if args[i] == "-p"
        config.Port = args[i+1]
      if args[i] == "ri"
        config.RequestInterval = args[i+1]
      if args[i] == "rp"
        config.RequestPath = args[i+1]
      if args[i] == "s"
        config.SearchString = args[i+1] 
    if !callerRef
      msg.send "Caller Reference is required"
      return
    if !type
      msg.send "Type is required"
      return
    params = 
      CallerReference: callerRef
      HealthCheckConfig: config

    route53.createHealthCheck params, (error, data) ->
      if error?
        msg.send "#{error}"
        return 
      msg.send "Health check #{data.HealthCheck.Id} was created successfully."

  robot.respond /delete health check ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params = 
      HealthCheckId: id
    route53.deleteHealthCheck params, (error, data) ->
      if error?
        msg.send "#{error}"
        return
      msg.send "Health check #{id} was deleted successfully."
