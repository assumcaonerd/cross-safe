INSERT INTO municipal_zones (name, zone_type, priority, geom)
SELECT 'Entorno escolar Camburi', 'school', 1,
       ST_GeogFromText('SRID=4326;POLYGON((-40.2876 -20.2845, -40.2836 -20.2845, -40.2836 -20.2805, -40.2876 -20.2805, -40.2876 -20.2845))')
WHERE NOT EXISTS (SELECT 1 FROM municipal_zones WHERE name = 'Entorno escolar Camburi');

INSERT INTO municipal_zones (name, zone_type, priority, geom)
SELECT 'Corredor escolar Laranjeiras', 'school', 1,
       ST_GeogFromText('SRID=4326;POLYGON((-40.2280 -20.1985, -40.2240 -20.1985, -40.2240 -20.1945, -40.2280 -20.1945, -40.2280 -20.1985))')
WHERE NOT EXISTS (SELECT 1 FROM municipal_zones WHERE name = 'Corredor escolar Laranjeiras');

INSERT INTO municipal_zones (name, zone_type, priority, geom)
SELECT 'Hospital Vila Velha - buffer', 'hospital', 1,
       ST_GeogFromText('SRID=4326;POLYGON((-40.3180 -20.3298, -40.3140 -20.3298, -40.3140 -20.3258, -40.3180 -20.3258, -40.3180 -20.3298))')
WHERE NOT EXISTS (SELECT 1 FROM municipal_zones WHERE name = 'Hospital Vila Velha - buffer');
