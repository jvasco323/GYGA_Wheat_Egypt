SPAM 2010 V1r1

*************
*Oct-08-2019*
*************
---------------------------------------------------------------
Differences compared to SPAM 2010 V1r0 (Uploaded December 2018)
---------------------------------------------------------------

- No more rounding errors of 0.1 ha or mt, ie areas and production in each pixel satisfy conditions: R=A-I and R=H+L+S.
- CSV files do not have 'strange' entries for Yemen - admin names with "," and ";" were corrected.
- Value of production only has one set of entries for Sudan - in previous version it had 2.
- Missing values for maize in Nigeria/Osun (fisp1=NI31) now included


*********************************************
Separate zip files for *.tif (GeoTiff) files:
*********************************************

spam2010V1r1_global_harv_area.geotiff.zip	tif files with values for harvested area (ha) for each crop and technology
spam2010V1r1_global_phys_area.geotiff.zip	tif files with values for physical area (ha) for each crop and technology
spam2010V1r1_global_prod.geotiff.zip		tif files with values for production (mt) for each crop and technology
spam2010V1r1_global_yield.geotiff.zip		tif files with values for yield (kg/ha) for each crop and technology
spam2010V1r1_global_val_prod.geotiff.zip	tif files with values for value of production (Int$) for each crop and technology (not always provided)
spam2010V1r1_global_val_prod_agg.geotiff.zip	tif files with aggregated values of production (Int$) for each crop and technology

File names
*************
All files have standard names, which allow direct identification of variable, crop and technology:
-----------------------------
spam2010V1r1_global_v_c_t.tif
-----------------------------
where
v = 	variable
c = 	crop 
t = 	technology

The values in each file correspond to the variable of the crop and technology included in the filename.
Other values are stored in the file as well, but they are part of the "tif" format.

v: Variables
---------------
A	physical-area
H	harvested-area
P	production
Y	yield
V	value of production	(not always included)
V_agg_s	aggregated value-of-production (does not distinguish crops)

s: sub-variable of V_agg
- - - - - - - - - - - - -
AREA_CR		area harvested of all crops
AREA_FO		area harvested of food crops
AREA_NF		area harvested of non-food crops
VP_CROP		value of production of all crops
VP_FOOD		value of production of food crops
VP_NONF		value of production of non-food crops
VP_CR_AR	value of production per ha of all crops
VP_FO_AR	value of production per ha of food crops
VP_NF_AR	value of production per ha of non-food crops

t: Technologies
---------------
*_A	all technologies together, ie complete crop
*_H	rainfed high inputs portion of crop
*_I	irrigated portion of crop
*_L	rainfed low inputs portion of crop
*_R	rainfed portion of crop (= A - I, or H + L + S)
*_S	rainfed subsistence portion of crop

c: Crops
---------------
crop #	full name	name		food/non-food crop
1	wheat		whea		food
2	rice		rice		food
3	maize		maiz		food
4	barley		barl		food
5	pearl millet	pmil		food
6	small millet	smil		food
7	sorghum		sorg		food
8	other cereals	ocer		food
9	potato		pota		food
10	sweet potato	swpo		food
11	yams		yams		food
12	cassava		cass		food
13	other roots	orts		food
14	bean		bean		food
15	chickpea	chic		food
16	cowpea		cowp		food
17	pigeonpea	pige		food
18	lentil		lent		food
19	other pulses	opul		food
20	soybean		soyb		food
21	groundnut	grou		food
22	coconut		cnut		food
23	oilpalm		oilp		non-food
24	sunflower	sunf		non-food
25	rapeseed	rape		non-food
26	sesameseed	sesa		non-food
27	other oil crops	ooil		non-food
28	sugarcane	sugc		non-food
29	sugarbeet	sugb		non-food
30	cotton		cott		non-food
31	other fibre crops ofib		non-food
32	arabica coffee	acof		non-food
33	robusta coffee	rcof		non-food
34	cocoa		coco		non-food
35	tea		teas		non-food
36	tobacco		toba		non-food
37	banana		bana		food
38	plantain	plnt		food
39	tropical fruit	trof		food
40	temperate fruit	temf		food
41	vegetables	vege		food
42	rest of crops	rest		non-food




