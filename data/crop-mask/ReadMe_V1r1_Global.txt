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

*****************************************************
Files in folder Global and naming conventions
*****************************************************

Zip files
*********
spam2010V1r1_global_harv_area.fff.zip	SPAM area harvested, global pixels, files in format fff for 6 technologies, strucuture A, record type H
spam2010V1r1_global_phys_area.fff.zip	SPAM physical area, global pixels, files in format fff for 6 technologies, strucuture A, record type A
spam2010V1r1_global_prod.fff.zip	SPAM production, global pixels, files in format fff for technologies, strucuture A, record type P
spam2010V1r1_global_yield.fff.zip	SPAM yield, global pixels, files in format fff for 6 technologies, strucuture A, record type Y
spam2010V1r1_global_val_prod_agg.fff.zip  SPAM value of production and area harvested, global pixels, files in format fff for 6 technologies, strucuture B, record type V

where
fff: File formats

*.dbf	FoxPlus, directly readable by ArcGis
*.csv	comma separated values

File names
*************
All files have standard names, which allow direct identification of variable and technology:
spam2010V1r0_global_v_t.fff
where
v = variable 
t = technology
fff = format

v: Variables
**************
*_A_*		physical area
*_H_*		harvested area
*_P_*		production
*_Y_*		yield
*_V_agg_*	value of production, aggregated to all crops, food and non-food (see below)

t: Technologies
******************
*_TA	all technologies together, ie complete crop
*_TI	irrigated portion of crop
*_TH	rainfed high inputs portion of crop
*_TL	rainfed low inputs portion of crop
*_TS	rainfed subsistence portion of crop
*_TR	rainfed portion of crop (= TA - TI, or TH + TL + TS)

fff: File formats
******************
*.dbf	FoxPlus, directly readable by ArcGis
*.csv	comma separated values

Structure A
**************
each pixel has
9 fields to identify a pixel:
   ISO3, prod_level (=fips2), alloc_key (SPAM pixel id), cell5m (cell5m id), x (x-coordinate - longitude of centroid), y (y-coordinate - latitude of centroid), rec_type (same in each zip file), tech_type (see technologies above), unit (same in each zip file, for all values)
42 fields for 42 crops: 
     similar to spam  notation: crop_T, where T = A, I, H, L, S or R
7 fields for annotations: 
   creation data of data, year_data (years of statistics used), source (source for scaling, always FAO avg2004-06), name_cntr, name_adm1, name_adm2 (all derived from prod_level field)

Structure B
**************
each pixel has
7 fields to identify pixel:
   ISO3, prod_level (=fips2), alloc_key (SPAM pixel id), cell5m (cell5m id), x (x-coordinate - longitude of centroid), y (y-coordinate latitude of centroid), rec_type (same in each zip file), tech_type (see technologies above), unit (same in each zip file, shows I$ .. international $, but only applies to VoP fields; unit of area harvested fields = ha)
9 fields for file with individual technologies: 
   vp_crop_T ( value of production of all 42 crops), VP_food_T (value of production of food crops), VP_nonf_T (value of produciton of non-food crops), area_cr_T (harvested area of all crops), area_fo_T (harvested area of food crops), area_nf_T (harvested area of non-food crops), vp_cr_ar_T (VoP per ha of all crops), vp_fo_ar_T (VoP per ha of food crops), vp_nf_ar_T (VoP per ha of non-food crops)
where T = A, I, H, L, S or R
7 fields for annotations: 
   creation data of data, year_data (years of statistics used), source (source for scaling, always FAO avg2004-06), name_cntr, name_adm1, name_adm2 (all derived from prod_level field)

Crops and classification food/non-food:
***************************************
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

