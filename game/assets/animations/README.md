# 动画资源

动画库使用角色ID和动作名命名。必需：idle、walk、run、jump、fall、land、basic_attack_1/2/3、skill_cast、hit_light、hit_heavy、dodge、block、victory、defeat。飞行职业另需 flight_idle、flight_move、flight_rise、flight_dive、air_attack。每个技能动画必须标注施法、命中和恢复事件帧。动画不能自行结算伤害；战斗系统仍是伤害判定唯一来源。