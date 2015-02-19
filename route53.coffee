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
         msg.send "Uh-oh. Something has gone wrong\n#{error}"
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
        msg.send "Uh-oh. Something has gone wrong\n#{error}"
        return
      zone = data.HostedZone
      msg.send "ID: #{zone.Id}\nName: #{zone.Name}\nCaller Reference: #{zone.CallerReference}"

  robot.respond /delete hosted zone ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params =
      Id: id
    route53.deleteHostedZone params, (error, data) ->
      if error?
        msg.send "Uh-oh. Something has gone wrong\n#{error}"
        return
      msg.send "Hosted zone #{id} was deleted successfully.\n"

  robot.respond /get hosted zone ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params =
      Id: id
    route53.getHostedZone params, (error, data) ->
      if error?
        msg.send "Uh-oh. Something has gone wrong\n#{error}"
        return
      zone = data.HostedZone
      msg.send "ID: #{zone.Id}\nName: #{zone.Name}\nCaller Reference: #{zone.CallerReference}"

  robot.respond /list health checks/i, (msg) ->
    route53.listHealthChecks {}, (error, data) ->
      if error?
        msg.send "Uh-oh. Something has gone wrong\n#{error}"
        return
      checks = data.HealthChecks
      for check in checks
        msg.send "ID: #{check.Id}\n#{check.CallerReference}\n#{check.HealthCheckConfig.IPAddress}\n#{check.HealthCheckConfig.Type}"

  robot.respond /list records ([\w.+\-\/]+)/i, (msg) ->
    id = msg.match[1]
    params = 
      HostedZoneId: id
    route53.listResourceRecordSets params, (error, data) ->
      if error?
        msg.send "Uh-oh. Something has gone wrong\n#{error}"
        return
      records = data.ResourceRecordSets
      for record in records
        message ="Name: #{record.Name}\nRecord Type: #{record.Type}\nTTL: #{record.TTL}"
        for rec in record.ResourceRecords
          message += "\n#{rec.Value}"
        if record.AliasTarget
          message += "\nDNSName: #{record.AliasTarget.DNSName}"
        msg.send "#{message}"
