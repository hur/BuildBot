#!/usr/bin/env python

import geni.portal as portal
import geni.rspec.pg as PG
import geni.rspec.igext as IG
import geni.rspec.emulab

pc = portal.Context()
rspec = PG.Request()

pc.defineParameter("token", "GitHub Token",
                   portal.ParameterType.STRING, "")

params = pc.bindParameters()

#
# Give the library a chance to return nice JSON-formatted exception(s) and/or
# warnings; this might sys.exit().
#
pc.verifyParameters()

builder = rspec.RawPC("builder")
builder.hardware_type = "d430"
builder.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
bs = builder.Blockstore("bs", "/buildbot")
bs.size = "80GB" # storage for android kernel sources

builder.addService(PG.Execute(shell="bash", command="/local/repository/scripts/master.sh " + params.token))

pc.printRequestRSpec(rspec)
