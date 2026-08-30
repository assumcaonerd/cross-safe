# Score municipal

R_c = (1.5 * hard_brake + 1.0 * occlusion) * Z
Z = 2 se a faixa esta a 80 m de school ou hospital.
LEVEL_1_CRITICAL se R_c >= 5.
GET /v1/municipal/priority-tickets?city=Vitoria
SQL: backend/sql/003_municipal_zones.sql
