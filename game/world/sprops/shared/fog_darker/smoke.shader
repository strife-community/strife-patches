<?xml version="1.0" encoding="UTF-8"?>
<shader>
	<node name="diffuse" type="sampler_2d" param="diffuse" />	
	<node name="diffuse2" type="sampler_2d" param="diffuse2" />	
	
	
	
	<node name="color" type="vertex_color" />		
	<node name="Material" type="material" />	
	
	
	
	
	<node name="vertPanner" type="panner" param="0 0.1" />
	<link from="vertPanner" to="diffuse"/>
		
	
	<node name="vertPanner2" type="panner" param="0 0" />
	<link from="vertPanner2" to="diffuse2"/>	
	



	<node name="multVertColor" type="add"/>
	<link from="diffuse2.a" to="multVertColor.A" />
	<link from="diffuse.a" to="multVertColor.B" />	

	<node name="multVertColor2" type="multiply"/>
	<link from="multVertColor" to="multVertColor2.A" />
	<link from="color" to="multVertColor2.B" />
	<!--
		
		-->
	
	<link from="diffuse" to="Material.Diffuse" />
	<link from="multVertColor2.r" to="Material.Opacity" />
	
</shader>
