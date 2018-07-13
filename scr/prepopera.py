#!/usr/bin/env python 
# A development of the old thinning script in order to do more proper thinning/superobbing
# of the polar volume radar data from opera in hdf5 files.
# 2. Changes the names of the files so they fit the existing script schaffolding
# 3. Script will skip files that has not been quality controlled
# 4. If thinning wanted instead of SuperObbing, Set thinning = 1 below!
# First version  on 2013-10-31 by mda@dmi.dk simple thinning on raw files 
# Second version on 2014-10-20 by mda@dmi.dk simple thinning on qc files
# Third version  on 2014-10-28 by mda@dmi.dk and martin.ridal@smhi.se SuperObbing and smarter thinning
# Fourth version on 2015-03-10 by mda@dmi.dk Parallalisation of the script!
# Fifth version on 2015-12-11 by mda@dmi.dk, ES,PT,IS included and many buggfixes and stability changes
# to make script more robust!
# Sixth version on 2016-01-27 by mda@dmi.dk, Added bias correctio possiblility and added VRAD if NI high enough!
# Seventh version on 2016-10-02 by martin.ridal@smhi.se, Improved super observations for winds by taking quality for 
# reflectivity into account
# Eighth version on 2016-10-17 by martin.ridal@smhi.se, Changed from using quality fields (unscaled) to quality index
# Nineth version on 2016-10-17 by martin.ridal@smhi.se, Added a selection of what country to process
#
# SuperObbing
# usage: arg1 = Date exemple 201511140200
# Thinning
# usage: arg1 = New resolution (m) exemple 2000.0
#        arg2 = Date exemple 201511140200
# ToDo: 
# Insert Max elevation angle!
# Insert alternative "more expensive" superobbing for VRAD when dealiased!
import os
import sys,getopt,string
import numpy as np
from array import *
import h5py
import glob
import time
import random
from multiprocessing import Process, Queue, current_process, freeze_support, cpu_count

# General Settings:
filematch ='*.h5'
thinning=0
# Some parameters that are needed as input
newrscale     = 6000     #Bin size in metres
newrayscale   = 3        #Azimuth angle in degrees
restorethresh = 0.55     #Level of quality to accept
clearsky_dbz  = 0        #Below this level, in dBz, is clear sky
arclim        = 6000     #Maximum size in ray direction

# Switch to allow use of VRAD fields that are  dealiased! 
dealiasing= True  # None
# Minimum Nyquist velocity that is allowed!
NI_min=30.0

#Individual Country Settings Change if Approppriate
dkname=["dkbor","dkrom","dksin","dkste","dkvir"]
dkid = ["06194","06096","06034","06173","06103"]
sename=["seang","searl","sehem","sehuv","sekir","sekkr","selek","selul","seosd","seovi","sevax","sevil"]
seid=["02606","02451","02588","02334","02032","02666","02430","02092","02200","02262","02600","02570"]
dename=["demem","deoft","deemd","deham","deros","dehan","debln","deess","defld","deumd","deneu","dedrs","denhb","detur","deeis","defbg","demuc","desna","depro","dehnr","deboo"]
deid=["10950","10629","10204","10147","10169","10338","10384","10410","10440","10356","10557","10488","10605","10832","10780","10908","10871","10873","10392","10339","10132"]
nlid=["06260","06234"]
nlname=["nldbl","nldhl"]
bename=["bejab","bewid"]
beid=["06410","06477"]
noname=["nobml","norst","noand","nohas","nosta","nohur","nohgb","norsa","nober","nosmn"]
noid=["01405","01104","01018","01042","01206","01498","01438","01247","01079","01136"]
plid=["12374","12514","12544","12579","12331","12220","12151","12568"]
plname=["plleg","plram","plpas","plrze","plpoz","plswi","plgda","plbrz"]
fiid=["02975","02941","02954","02918","02933","02870","02840","02925","02995","02775"]
finame=["fivan","fiika","fianj","fikuo","fikor","fiuta","filuo","fivim","fikes","fipet"]
eeid=["26038","26232"]
eename=["eehar","eesur"]
frid=["07145","07005","07510","07255","07436","07129","07182","07658","07629","07167","07461","07223","07569","07745","07381","07671","07108","07774","07637","07083","07336","07274","07606","07291"]
frname=["frtra","frabb","frbor","frbou","frgre","frcae","frnan","frnim","frtou","frtro","frlep","frtre","frbol","fropo","frniz","frcol","frpla","frale","frmcl","frave","frche","frbla","frmom","frmtc"]
ieid=["03962","03969"]
iename=["iesha","iedub"]
hrid=["14256","14280"]
hrname=["hrbil","hrosi"]
ukid=["03918","03675","03842","03601","03859","03086","03331","03142","03253","03375","03897","03018","03159","03813","03771","03523"]
ukname=["ukcas","ukche","ukcob","ukcyg","ukdea","ukdud","ukham","ukhhd","ukhmy","uking","ukjer","uklew","ukmun","ukpre","ukthu","ukcle"]
ptid=["08550","08553","08556"]
ptname=["ptlis","ptfar","ptprt"]
isid=["09999","09998"]
isname=["iskef","istgb"]
esid=["08479","08262","08179","08007","08072","60028","08228","08475","08364","08308","08019","08386","08081","08289","08162"]
esname=["esalm","esbad","esbar","escor","eslid","eslpa","esmad","esmal","esmur","espma","essan","essev","essse","esval","eszar"]
#------------------------
#
# Function run by worker processes
#

def worker(input):
    for func, args in iter(input.get, 'STOP'):
        calculate(func, args)

#
# Function used to calculate result
#

def calculate(func, args):
    func(*args)
    return '%s says that %s%s ' % \
        (current_process().name, func.__name__, args)

#------------------------
def read_cal(filename):
    calname=[]
    calbias=[]
    radarnames=['ekrn','ekxr','eksn','ekxs','ekxr']
    dkname=["dkbor","dkrom","dksin","dkste","dkvir"]
    name=filename[0:5]
    bias=0.0
    # check the order of that list!
    fc = open('/data6/mda/radarscripts/biases.txt','r')
    print 'in read_cal ',os.getcwd()
#   fc = open('../../biases.txt.2','r')
    for line in fc:
        line = line.strip()
        columns = line.split()
        in_name = columns[0]
        in_bias = float(columns[3])
        print 'bias',in_bias,' name : ',in_name
        calname.append(in_name)
        calbias.append(in_bias)
    for i in range(len(calname)):
        if calname[i] == 'ekxv': calname[i]='dkvir'
        if calname[i] == 'ekxs': calname[i]='dkste'
        if calname[i] == 'eksn': calname[i]='dksin'
        if calname[i] == 'ekxr': calname[i]='dkrom'
        if calname[i] == 'ekrn': calname[i]='dkbor'
        print 'name = ',name,' calname = ',calname[i]
        if calname[i] == name: 
            bias = calbias[i]
    return bias

def find_attr(fid,attr_name):
# find number of scans!
     number_of_scans=scan_nr(fid)    
     attr_group_list=["how","what","where"]
     result=0
     scan_list=[]
     for scan_number in range(number_of_scans+1):
         if (scan_number==0):
             scan_list.append("") 
         else:
             scan_name="/dataset%d/" % (scan_number)
             scan_list.append(scan_name)
     for path_item in scan_list:
         for group_item in attr_group_list:
             pathname=path_item +  group_item 
             if pathname in fid.keys():
                 attr_local = fid[pathname]
                 for item in attr_local.attrs.keys(): 
                     if (item==attr_name):
                         result = attr_local.attrs[attr_name]
     return result
#------------------------
def check_wmoid(fid,fname):
    if fname in dkname:
        antgainH = find_attr(fid,'antennagain')
        if (antgainH==0):
            antgainH=45.0
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.8
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
        sensitivity = -108.0
    if fname in sename:
        antgainH = find_attr(fid,'antgainH')
        if (antgainH==0):
            antgainH=44.9
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.58
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.35
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
        sensitivity = -108.0
    if fname in dename:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.0
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
        sensitivity = -108.0
    if fname in ukname:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.0
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.815
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.329
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in nlname:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.3
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
 #      print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in bename:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.3
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in noname:
        antgainH = find_attr(fid,'antgainH')
        if (antgainH==0):
            antgainH=45.0
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.5
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.35
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgainH = ',antgainH
        sensitivity = -108.0
    if fname in plname:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.0 # Polish Radars lack this number at the moment! 
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79 # Polish Radars lack this number at the moment! 
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.35
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in finame:
        antgainH = find_attr(fid,'antgainH')
        if (antgainH==0):
            antgainH=45.6 
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79 
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgainH = ',antgainH
        sensitivity = -108.0
    if fname in eename:
        antgainH = find_attr(fid,'antgainH')
        if (antgainH==0):
            antgainH=45.6
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgainH = ',antgainH
        sensitivity = -108.0
    if fname in frname: # French Radar Data lacks these numbers, found them in an article
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.3
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in esname:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.3
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in ptname:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.3
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.79
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in iename:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.0
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.8
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.33
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in isname:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.0 # missing number
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.58 # missing number
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.4375
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0
    if fname in hrname:
        antgain = find_attr(fid,'antgain')
        if (antgain==0):
            antgain=45.0 # missing number
        pulsewidth = find_attr(fid,"pulsewidth")
        if (pulsewidth==0):
            pulsewidth=0.8 # missing number
        wavelength = find_attr(fid,"wavelength")
        if (wavelength==0):
            wavelength=5.3
        elif ((wavelength>0) and (wavelength < 0.1)):
            wavelength=100.0*wavelength
#       print 'wavelength = ',wavelength,' pulsewidth =',pulsewidth,' antgain = ',antgain
        sensitivity = -108.0

    return antgainH,pulsewidth,wavelength,sensitivity
    
def copyattr(groupoid,name,groupood):
    global nbinsp,factorp,nrays,nbins
    if (name) not in groupood:
       group=groupood.create_group(name)

    for item in groupoid.attrs.keys():
        if (item == 'rscale'):
#          group.attrs[item] = newrscale
           group.attrs.create(item,newrscale,dtype=np.float64)
#          print "attribute type = ",group.attrs[item].dtype
        elif (item == 'nbins'):
           factor = groupoid.attrs['rscale']/newrscale
           factorp = int(1/factor)
           nbins = groupoid.attrs[item]
           nbinsp = int(nbins*factor)
           group.attrs[item] = nbinsp
        elif (item == 'nrays'):
           nrays = groupoid.attrs[item]
           group.attrs[item] = groupoid.attrs[item]
        else:
           group.attrs[item] = groupoid.attrs[item]

def oldgrid(groupoid,name):
    global nrays,nbins,rscale
    for item in groupoid.attrs.keys():
        if (item == 'rscale'):
           rscale = groupoid.attrs['rscale']
        if (item == 'nbins'):
           nbins = groupoid.attrs[item]
        if (item == 'nrays'):
           nrays = groupoid.attrs[item]

def getgrid(groupoid,name):
    global nbinsp,factorp,nrays,nbins
    for item in groupoid.attrs.keys():
        if (item == 'nbins'):
           factor = groupoid.attrs['rscale']/newrscale
           factorp = int(1/factor)
           nbins = groupoid.attrs[item]
           nbinsp = int(nbins*factor)
        elif (item == 'nrays'):
           nrays = groupoid.attrs[item]

def newgrid(nbins,nrays,rscale,newrscale,newrayscale):
  # Calculates the new thinner grid to be used by all elevations
  binfactor = int(newrscale/rscale)
  newnbins  = int(nbins/binfactor)

  rayscale  = 360./nrays
  if (thinning == 1):
      rayfactor = int(round(1.0/rayscale))
  else:
      rayfactor = int(round(newrayscale/rayscale))

  newnrays  = int(nrays/rayfactor)

  return newnbins,newnrays,binfactor,rayfactor

def scan_nr(fid):
    nscans = 0
    groupid = fid['/']
    for item in groupid.keys():
        if "dataset" in item: nscans = nscans + 1

#   print "Number of datasets =",nscans
    return nscans

def nr_quality(groupid):
    quality_fields = 0
    for item in groupid.keys():
        if "quality" in item: quality_fields = quality_fields + 1

    return quality_fields

def nr_datas(groupid):
    datas = 0
    for item in groupid.keys():
        if "data" in item: datas = datas + 1

    return datas

def controlled(fid):
    table = fid['/dataset1/']
    for item in table.keys():
        if ('quality' in item): 
            qc_check = 1
            return qc_check 
        else:
            qc_check = 0
    return qc_check

def overlapping(fid):
   table = fid['how']
#  if ('nscans' in table.attrs.keys()):
#     nscans = table.attrs['nscans']
#  else:
   nscans = scan_nr(fid)
   beamwidth = find_attr(fid,'beamwidth')
   if (beamwidth == 0):
       beamwidth = 1.0
#  if ('beamwidth' in table.attrs.keys()):
#     beamwidth = table.attrs['beamwidth']
#  else:
#     beamwidth = 1.0
   print"There are ",nscans," scans in file with a beamwidth = ",beamwidth
   groupid=fid['/']
   lowest=90.0
   scanlist=[]
   anglelist=[]
   for i in range(nscans):
       j=i+1
       grpn = "/dataset%d" % (j) + "/where/"
       wgrpn = fid[grpn]
       elangle = wgrpn.attrs['elangle']
       if (elangle < lowest): 
           lowest=elangle
           lscan=j

   scanlist.append(lscan)
   anglelist.append(lowest)
   print "scan nr:",lscan,"contains the elevation smallest angle = ",lowest
   while (len(scanlist) < nscans):
       lowest=90.0
       nextscan=100
       for i in range(nscans):
           j=i+1
           if (j not in scanlist):
               grpn = "/dataset%d" % (j) + "/where/"
               wgrpn = fid[grpn]
               elangle = wgrpn.attrs['elangle']
               if (elangle < lowest):
                   lowest=elangle
                   nextscan=j    
       scanlist.append(nextscan)
       anglelist.append(lowest)
             
   print "Order of scans : ",scanlist           
   print 'Angles of scans :',["%0.2f" % i for i in anglelist]
   finallist=scanlist
   for i in reversed(range(len(scanlist))):
       if (i>0):
           if (anglelist[i]-anglelist[i-1] < 0.5*beamwidth):
               if (anglelist[i-1] >= beamwidth*0.5):
#                  print i,anglelist[i],anglelist[i-1]
#                  print "removing = ",i,anglelist[i]
                   del finallist[i]
                   del anglelist[i]
               else:
#                  print i
                   break
#  print "part finallist = ",finallist
#  print "part anglelist = ",anglelist
   deadlist=finallist
#  print deadlist
#  print anglelist
   for i in reversed(range(len(deadlist))):
       if (beamwidth*0.5 > anglelist[i]):
#          print i,finallist[i]
           del finallist[i]
   print "Final list after removal scheme "
   print "Order of scans : ",finallist           
   print "Length of final list : ",len(finallist)
   return finallist
           
def createthin(data,quality,gain,offset,nbins,nrays,newnbins,newnrays,binfactor):

# dataso    = zeros((newnrays,newnbins))
# qualityso = zeros((newnrays,newnbins))
  dataso    = np.zeros((newnrays,newnbins)) + 255
  qualityso = np.zeros((newnrays,newnbins)) + 255

  for rray in range (0,nrays):
      newbbins=0
      for bbin in range(0,nbins,binfactor):
          datatmp = data[rray,bbin:bbin+binfactor]
          qualtmp = quality[rray,bbin:bbin+binfactor]
          mindex = np.argmin(qualtmp)
          dataso[rray,newbbins]=data[rray,bbin+mindex]
          qualityso[rray,newbbins]=quality[rray,bbin+mindex]
#         print rray,nrays,bbin,nbins,binfactor, newbbins, newnbins
#         print dataso.shape,qualityso.shape
          if ( (newbbins + binfactor) > newnbins ):
              break
          else:
              newbbins= newbbins + 1

  return dataso,qualityso

# ------------------

def createso(data,quality,gain,offset,qgain,qoffset,nbins,nrays,newnbins,newnrays,binfactor,rayfactor,restorethresh,clearsky,rscale,bias):
  # All observations below xx dBz is regarded as clear sky
  # For radial wind this is set to zero
  clearlim = (clearsky - offset)/gain

 # Create the new matrices initialized with "nodata"
# dataso    = zeros((newnrays1,newnbins1)) + 255
# qualityso = zeros((newnrays1,newnbins1)) + 255
  dataso    = np.zeros((newnrays,newnbins)) + 255
  qualityso = np.zeros((newnrays,newnbins)) + 255
  
  # Step through the rays in steps of rayfactor
  # and bins in steps of bin factor to craete a small tmp matrix
  raycount = -1

  for rray in range (0,nrays,rayfactor):
      if (rray+rayfactor > nrays):
          break

      raycount = raycount + 1
      bincount = -1
      for bbin in range (0,nbins,binfactor):
          if(bbin+binfactor > nbins):
              break

          bincount = bincount + 1

          radius = bbin * rscale
          arclength = (nrays/360)*rayfactor/360 * np.pi * 2 * radius
          if (arclength/arclim <= 1):
             rayfactor1 = rayfactor
          elif (arclength/arclim <= 2) and (arclength/arclim > 1):
             rayfactor1 = rayfactor-1
          else:      
             rayfactor1 = rayfactor-2
          if (rayfactor1 < 1):
              rayfactor = 1
          
          datatmp = data[rray:rray+rayfactor1,bbin:bbin+binfactor]
          qualtmp = quality[rray:rray+rayfactor1,bbin:bbin+binfactor]

          # Calculate how many obspoints gives i.e. 30% of the superobs
          # To be used with count1
          col,row = np.shape(datatmp)
          noobsinso = col*row
          percentage = int(noobsinso*0.3)          
          
      
          # Create a super obs from this smaller matrix if conditions are fulfilled 
          count1 = 0
          count2 = 0
          count3 = 0
          sotmp  = 0
          for raytmp in range (0,rayfactor1):
              for bintmp in range (0,binfactor):
                  if (datatmp[raytmp,bintmp] > clearlim) and ((qualtmp[raytmp,bintmp]*qgain+qoffset > restorethresh) or (qualtmp[raytmp,bintmp] == 255)): 
                      sotmp  = sotmp + datatmp[raytmp,bintmp]
                      count1 = count1 + 1
                  elif (datatmp[raytmp,bintmp] <= clearlim) and ((qualtmp[raytmp,bintmp]*qgain+qoffset > restorethresh) or (qualtmp[raytmp,bintmp] == 255)): 
                      count2 = count2 + 1
                  else:
                      count3 = count3 + 1

          if (count1>percentage):
              # Rainy pixels of good quality
              # need to know the filename and hence get the correct bias value
              # if name is in list then add/subtract scaling value from list using alpha*bias+beta
              if (bias !=0.0):
                  temp1=((sotmp/count1)*gain+offset)+bias
                  temp2=(temp1-offset)/gain
#                 print sotmp/count1,((sotmp/count1)*gain+offset),bias,temp2
                  if (temp2<0):
                      temp2=0
                  elif (temp2>254):
                      temp2=254
                  dataso[raycount,bincount] = temp2
#                 dataso[raycount,bincount] = sotmp/count1-(bias+32.0)/0.5
              else:
                  dataso[raycount,bincount] = sotmp/count1
              qualityso[raycount,bincount] = int((0.9-qoffset)/qgain)      # Arbitrary value above restorthresh
          elif(count2>0):
              # Clear pixels of good quality
              dataso[raycount,bincount] = 0
              qualityso[raycount,bincount] = int((0.9-qoffset)/qgain)    # Arbitrary value above restorthresh
          else:
              # All pixels are of poor quality
              dataso[raycount,bincount] = 254     # Arbitrary value within observation range
              qualityso[raycount,bincount] = int((0.1-qoffset)/qgain)  # Arbitrary value below restorthresh
           
  return dataso,qualityso

# ------------------

def createso_dow(data,quality,qgain,qoffset,nbins,nrays,newnbins,newnrays,binfactor,rayfactor,restorethresh,rscale):

 # Create the new matrices initialized with "nodata"
# dataso    = zeros((newnrays1,newnbins1)) + 255
# qualityso = zeros((newnrays1,newnbins1)) + 255
  dataso    = np.zeros((newnrays,newnbins)) + 255
  qualityso = np.zeros((newnrays,newnbins)) + 255

  # Step through the rays in steps of rayfactor
  # and bins in steps of bin factor to create a small tmp matrix
  raycount = -1

  for rray in range (0,nrays,rayfactor):
      if (rray+rayfactor > nrays):
          break

      raycount = raycount + 1
      bincount = -1
      for bbin in range (0,nbins,binfactor):
          if(bbin+binfactor > nbins):
              break

          bincount = bincount + 1

          radius = bbin * rscale
          arclength = (nrays/360)*rayfactor/360 * np.pi * 2 * radius
          if (arclength/arclim <= 1):
             rayfactor1 = rayfactor
          elif (arclength/arclim <= 2) and (arclength/arclim > 1):
             rayfactor1 = rayfactor-1
          else:      
             rayfactor1 = rayfactor-2
          if (rayfactor1 < 1):
              rayfactor = 1
          
          datatmp = data[rray:rray+rayfactor1,bbin:bbin+binfactor]
          qualtmp = quality[rray:rray+rayfactor1,bbin:bbin+binfactor]

          # Calculate how many obspoints gives i.e. 30% of the superobs
          # To be used with count1
          col,row = np.shape(datatmp)
          noobsinso = col*row
          percentage = int(noobsinso*0.3)          
          
      
          # Create a super obs from this smaller matrix if conditions are fulfilled 
          count1 = 0
          count3 = 0
          sotmp  = 0
          for raytmp in range (0,rayfactor1):
              for bintmp in range (0,binfactor):
                  if (datatmp[raytmp,bintmp] < 255) and (datatmp[raytmp,bintmp] > 0) and ((qualtmp[raytmp,bintmp]*qgain+qoffset > restorethresh) or (qualtmp[raytmp,bintmp] == 255)): 
                      count1 = count1 + 1
                      if (count1 == 1):
                          sotmp = np.array([datatmp[raytmp,bintmp]])
                      else:
                          sotmp = np.append(sotmp,datatmp[raytmp,bintmp])
                  else:
                      count3 = count3 + 1
          if (count1>percentage):
              # Enough information to create a superobs
              # Check that the std is not too large
              tmpmean = np.mean(sotmp)
              stdtmp  = np.std(sotmp)
#              print "STD = ",stdtmp, tmpmean, count1
              if (stdtmp < 10):
                  dataso[raycount,bincount] = tmpmean
                  qualityso[raycount,bincount] = int((0.9-qoffset)/qgain)      # Arbitrary value above restorethresh, not really used
              else:
                  # Too large std to be used
                  dataso[raycount,bincount] = 255     # No data
                  qualityso[raycount,bincount] = int((0.1-qoffset)/qgain)  # Arbitrary value below restorethresh, not really used
          else:
              # Too few observations in this subset to be used
              dataso[raycount,bincount] = 255     # No data
              qualityso[raycount,bincount] = int((0.1-qoffset)/qgain)  # Arbitrary value below restorethresh, not really used
           
  return dataso,qualityso

# ------------------

def convert(filename,dummy):
    fid = h5py.File(filename, mode = "r",libver='earliest')
    fname=filename[0:5]
# Check Variables like gain and offset!
# rename unambiguousvelocity to VI etc in Version
    print "Now working on file = ",filename
#   find_attr(fid,"wavelength")
    qc_checked = 0
    qc_checked=controlled(fid)
    if (qc_checked == 0):
       print "------------------------------------------"
       print 'WARNING:'
       print 'File not quality controlled, skipping = ',filename  
    else:
        table = fid['how']
        if ('nscans' in table.keys()):
           nscans = table.attrs['nscans']
        else:
           nscans = scan_nr(fid)
        if ( nscans > 1 ):
            finallist=overlapping(fid)
        else:
            finallist=[1]
            print "Only one elevation => No elevation check made!!"
# if existing read up bias config file
#        print 'before calling read_cal ',os.getcwd()
        if (os.path.isfile('/data6/mda/radarscripts/biases.txt')):
            bias=read_cal(fname)
        else:
            bias=0.0

#        print 'For the radar : ',filename[0:5],' there is a bias of ',bias,' reported!'
#       print "inside convert we have ",finallist
# Opening a new file for writing with a pre-index of 'r'
#       pfilename='../' + proroot+'/'+'r'+filename
        pfilename=proroot+'/'+'r'+filename
        print 'Output file =',pfilename
#       with h5py.File(pfilename, mode = "w") as fod: 
        fod = h5py.File(pfilename, mode = "w")
# Reading and storing the root layer attributes
# HOW
# 
        copyattr(table,'how',fod)

# WHERE
        table = fid['where']
        copyattr(table,'where',fod)

# WHAT
        table = fid['what']
        copyattr(table,'what',fod)

# loop through the datasets and break if elevation angle to steep!
        setnr = 0
        count = 0
#       print "number of scans:",len(finallist)
        table = fod['/how']
        table.attrs['nscans']=len(finallist)

#       print len(finallist)
        for i in range(len(finallist)):
           varnr = 0
           setnr = setnr + 1
# new datasetX to outfile
           grpn = "/dataset%d" % (setnr)
           grpo = fod.create_group(grpn)
           grpow = grpn + '/where'
           grpohow = grpn +'/how'
# old datasetX from in file
           grps = "/dataset%d" % (finallist[setnr-1])
#          print "dataset = ",grps
           grpi = fid[grps]
           grpsw = grps + '/where'
           wherei = fid[grpsw]
           oldgrid(wherei,grpow)
           nbinsp,nraysp,binfactor,rayfactor=newgrid(nbins,nrays,rscale,newrscale,newrayscale) 
# here the newgrid parameters should be used!!
           copyattr(wherei,grpow,grpo)
           grpih = grps + '/how'
           grpoh = grpn + '/how'
           grpihh = 'how'
           if grpihh in grpi.keys():
              howi = fid[grpih]
              copyattr(howi,grpoh,grpo) 
              antgainH,pulsewidth,wavelength,sensitivity = check_wmoid(fid,fname)
              fod[grpoh].attrs['sensitivity']=sensitivity
              if "antgainH" not in grpo.attrs:
                  fod[grpoh].attrs['antgainH']=antgainH
              if "pulsewidth" not in grpo.attrs:
                  fod[grpoh].attrs['pulsewidth']=pulsewidth
              if "wavelength" not in grpo.attrs:
                  fod[grpoh].attrs['wavelength']=wavelength
           else:
               grouphow = fod.create_group(grpoh)
               antgainH,pulsewidth,wavelength,sensitivity = check_wmoid(fid,fname)
               grouphow.attrs['antgainH'] = antgainH
               grouphow.attrs['pulsewidth']=pulsewidth
               grouphow.attrs['wavelength']=wavelength
               grouphow.attrs['sensitivity']=sensitivity

# put in check of wmoid here and direct to correct fix subroutine!
# datasetX/what
           grpiw = grps + '/what'
           grpow = grpn + '/what'
           whati = fid[grpiw]
           copyattr(whati,grpow,grpo)
           nr_vars = nr_datas(grpi)
           qdata  = np.zeros((int(nrays),int(nbins)))
           pqdata = np.zeros((int(nraysp),int(nbinsp)))
#        This is introduced for those that does not have the latest baltrad qc package!
#        New version of Baltrad QC puts in a qi_total for the total quality index and
#        that should be the default, otherwise it is going the old route with collective 
#        quality index in quality1
           datasetid="/dataset%d/" % (finallist[setnr-1])
           datasetgrp=fid[datasetid]
           quality_fields=nr_quality(datasetgrp)
           for q_nr in range(1,quality_fields+1):
               dsetnqh = "/dataset%d/quality%d/how" % (finallist[setnr-1],q_nr)
#              print 'dsetnqh =',dsetnqh
               qhow=fid[dsetnqh]
               if "qi_total" in qhow.attrs['task']:
                   dsetnq = "/dataset%d/quality%d" % (finallist[setnr-1],q_nr)
#                  print "found qi_total in qualityset ",q_nr
                   break
               else:
                   dsetnq = "/dataset%d/quality1" % (finallist[setnr-1])
#                  print "No qi_total found, using ",dsetnq
#          print "Path to quality index ",dsetnq
           dsetnq  = "/dataset%d/quality1" % (finallist[setnr-1])
           grpqno  = "/dataset%d/quality1" % (setnr)  #Will always be quality1
           grpqo   = fod.create_group(grpqno)
           grpqow  = grpqno + '/what'
           grpqoh  = grpqno + '/how'
           grpq    = fid[dsetnq]
           qdata   = grpq['data'].value
           dsetnqw = dsetnq+"/what"
           dsetnqh = dsetnq+"/how"
           qwhat   = fid[dsetnqw]
           qhow    = fid[dsetnqh]
           copyattr(qwhat,grpqow,grpqo)
           copyattr(qhow,grpqoh,grpqo)
           qoffset = qwhat.attrs['offset']
           qgain   = qwhat.attrs['gain']

           dbzh_found=0
           vrad_found=0
           do_both= None
           for j in range(nr_vars):
              dsetnm = "/dataset%d/data%d" % ((finallist[setnr-1]), (j+1))
              anm = dsetnm+'/what'
              grp = fid[anm]
              if (grp.attrs['quantity'] == 'DBZH'): dbzh_found=1 
#              if ((grp.attrs['quantity'] == 'VRAD') and (filename[0:2]=='dk')):
#                  # Readup unambigousvelocity from /how/unambiguousvelocity to NI
#                  grpni=fid['/how']
#                  NI=grpni.attrs['unambiguousvelocity']
#                  alpha_vr=(NI/127.0)
#                  beta_vr=((-128.0/127.0)*NI)
#                  grp.attrs['gain']=alpha_vr
#                  grp.attrs['offset']=beta_vr
              quantity_name=grp.attrs['quantity']
#              print 'quantity name = ',quantity_name[0:4]
              if ((quantity_name[0:4] == 'VRAD') and ((float(grp.attrs['gain'])*127.0)>NI_min) and (dealiasing)): 
#             if ((grp.attrs['quantity'] == 'VRAD') and ((float(grp.attrs['gain'])*127.0)>30.0) and (dealiasing)): 
                  vrad_found=1 
#                  print 'NI=',float(grp.attrs['gain'])*127.0
           if ((dbzh_found==1) and (vrad_found==1)): do_both=True

           for j in range(nr_vars):
              dsetnm = "/dataset%d/data%d" % ((finallist[setnr-1]), (j+1))
              anm = dsetnm+'/what'
              grp = fid[anm]
              quantity_name=grp.attrs['quantity']
              if ((quantity_name[0:4] == 'DBZH') or ((quantity_name[0:4] == 'VRAD') and (do_both))):
#             if (grp.attrs['quantity'] == 'DBZH') or ((grp.attrs['quantity'] == 'VRAD') and (do_both)):
                 varnr = varnr + 1
                 data   = np.zeros((int(nrays),int(nbins)))
                 pdata  = np.zeros((int(nraysp),int(nbinsp)))
                 newname="/dataset%d" % (setnr)
                 grpo=fod ["/"]
# Reading the attributes from the input file
                 anmo = newname+"/data%d" % (varnr) + '/what'
                 copyattr(grp,anmo,grpo)
                 offset=grp.attrs['offset']
                 gain=grp.attrs['gain']
# ----------------------
                 anw = newname + '/where'
                 fod[anw].attrs['nbins']=nbinsp 
                 fod[anw].attrs['nrays']=nraysp
# And now for the data 
                 grpd=fid[dsetnm]
                 data = grpd['data'].value
                 quantity_name=grp.attrs['quantity']
             # Reflectivity
                 if (quantity_name[0:4] == 'DBZH'):
#                if (grp.attrs['quantity'] == 'DBZH'):
                     clearsky = clearsky_dbz
                     if (thinning == 1):
                         pdata,pqdata = createthin(data,qdata,gain,offset,nbins,nrays,nbinsp,nraysp,binfactor)
                     else:
                         pdata,pqdata = createso(data,qdata,gain,offset,qgain,qoffset,nbins,nrays,nbinsp,nraysp,binfactor,rayfactor,restorethresh,clearsky,rscale,bias)            
             # Doppler Wind
                 if ((quantity_name[0:4] == 'VRAD') and (do_both)):
#                if ((grp.attrs['quantity'] == 'VRAD') and (do_both)):
                     clearsky = offset
                     if (thinning == 1):
                         pdata,dummydata = createthin_dow(data,qdata,qgain,qoffset,nbins,nrays,nbinsp,nraysp,binfactor)
                     else:
                         pdata,dummydata = createso_dow(data,qdata,qgain,qoffset,nbins,nrays,nbinsp,nraysp,binfactor,rayfactor,restorethresh,rscale)            

                 dataname="/dataset%d/data%d" % ((setnr), (varnr))+'/data'
                 fod.create_dataset(dataname,data=np.int_(pdata),chunks=(int(nraysp),int(nbinsp)),compression='gzip',compression_opts=6)

           qualityname="/dataset%d/quality1" % ((setnr))+'/data'
           fod.create_dataset(qualityname,data=np.int_(pqdata),chunks=(int(nraysp),int(nbinsp)),compression='gzip',compression_opts=6)
    fod.close() # buggfix added by mbs@dmi.dk    

if __name__ == "__main__":
    freeze_support()
    start = time.time()

# Check the input arguments
    newroot = ''
    proroot = ''
    argv = sys.argv[1:]
    try:
        opts, args = getopt.getopt(argv,"hd:i:o:",["date=","indir=","outdir="])
    except getopt.GetoptError:
        print 'prepopera.py -d <yyyymmdhh> -i <inputdir> -o <outputdir>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'prepopera.py -d <yyyymmddhh> -i <inputdir> -o <outputdir>'
            sys.exit()
        elif opt in ("-d", "--date"):
            sdate = arg
        elif opt in ("-i", "--indir"):
            newroot = arg
        elif opt in ("-o", "--outdir"):
            proroot = arg
    print 'Date is       :', sdate
    print 'Input dir is  :', newroot
    print 'Output dir is :', proroot

#    print "Number of arguments:", len(sys.argv), 'arguments.'
#    print "Argument List:", str(sys.argv)
#    datum   = int(sys.argv[1])
#    newroot = str(sys.argv[2])
#    proroot = str(sys.argv[3])

    nocpu=cpu_count()
    NUMBER_OF_PROCESSES = nocpu
    print 'Number of available threads: '
    print nocpu
#    sdate=sys.argv[1]
    YY=sdate[:4] 
    MM=sdate[4:6]
    DD=sdate[6:8]
    HH=sdate[8:10]
    MI=sdate[10:12]
#    proroot= proroot + '/' + YY + '/' + MM + '/' + DD
    if not os.path.exists(proroot):
        os.makedirs(proroot)

    os.chdir(newroot)
    newrscale_store = newrscale

    # Specify which countries to process, e.g. [sename, dkname, finame]
    countries=[sename,dkname,finame,eename]
    #countries=[sename]
    fcountries=[]
    ffiles=[]
    for co in countries:
        fcountries.extend( co )

    for cnames in fcountries:
        fnames=cnames + '_qcvol_pn129_*' + YY + MM + DD + "T" + HH + MI + '*Z*.h5'
        ffiles.extend( glob.glob(fnames) )
        length = len(glob.glob(fnames))
        if (length == 0):
            print 'Radar ' + cnames + ' does not exist for this date.'

    print ffiles
    print newroot
    inumb=1
    TASKS = [(convert, (vfile,0)) for vfile in ffiles]
#    print TASKS
    # Create queues
    task_queue = Queue()
    # Submit tasks
    for task in TASKS:
        task_queue.put(task)
    # Start worker processes
    for i in range(NUMBER_OF_PROCESSES):
        Process(target=worker, args=(task_queue,)).start()
    # Tell child processes to stop
    for i in range(NUMBER_OF_PROCESSES):
        task_queue.put('STOP')



 #      for vfile in glob.glob(fnames):
 #          print "------------------------------------------"
 #          print "Processing ",inumb," of ",len(glob.glob(fnames))
 #          print "------------------------------------------"
 #          print vfile
 #          convert(vfile)
 #          inumb = inumb + 1

    end = time.time()
    print "------------------------------------------"
    print "The preprocessing time of ",len(glob.glob(fnames))," took : ",(end-start)
    print "Meaning a total of ",((end-start)/60.0)," min "
#    print "Meaning a total of ",((end-start)/60.0)," min or ",((end-start)/(len(glob.glob(fnames))))," sec/file"
 
