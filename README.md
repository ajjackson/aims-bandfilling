aims-bandfilling
================

Calculates a conducting band-filling correction for shallow n-type defects from FHI-aims 
output files. This is useful for extrapolating a finite defect energy to the dilute limit 
when performing periodic ab-initio calculations on defective semiconductors. For a localised 
defect state in the band gap of a material the correction should be close to zero.

Used to analyse GaN: Jackson, A.J. and Walsh, A., *Physical Review B* **88**, 165201 (2013).
http://dx.doi.org/10.1103/PhysRevB.88.165201

For more information on this calculation see:
Persson et al, *Physical Review B* **72**, 035211 (2005). http://dx.doi.org/10.1103/PhysRevB.72.035211

This project is not officially affiliated with FHI-aims.


----------------
To do:
Automate k-point weighting
*check FHI-aims output file
*if not in file (FHI-aims requires a flag to be set, not available in earlier versions)
 check file in directory named "k-weighting.conf"
