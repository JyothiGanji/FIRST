from PIL import Image
from distutils import sysconfig as s; 

import os.path
if not os.path.isfile(os.path.join(s.get_config_vars()['INCLUDEPY'], 'Python.h')) :
    print 'python-devel not installed'

