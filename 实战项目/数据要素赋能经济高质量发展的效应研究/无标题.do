*准备工做
cls
clear all
set more off
unicode encoding set UTF-8
*安装包

*设置文件路径
cd "D:\stata\program\统计工程期末"

*导入数据
import delimited "数据要素赋能数据分析源文件2.csv"

*定义数据类型
gsort province_id year //排序
stset province_id year //定义面板

*定义全局变量
global DV hqed // 应变量
global IV de   // 核心自变量
global CV open gov facility rd it //控制变量
*global MV    //中介变量
global OPT absorb(year province_id) vce(robust) //回归Option
global OPT1 absorb(year province_id) vce(robust) //回归Option1

**描述性统计
*python输出

*基准回归
xtset province_id year

*基础回归：双向固定效应模型

reg $DV $IV ,vce(ols)  //普通标准误
estadd local 省份固定效应 "否"
estadd local 年份固定效应 "否"
*将结果存储到内存
est sto M1

reg $DV $IV $CV,vce(ols)
estadd local 省份固定效应 "否"
estadd local 年份固定效应 "否"
*将结果存储到内存
est sto M2

reg $DV $IV i.year i.province_id,vce(ols)
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
*将结果存储到内存
est sto M3

reg $DV $IV $CV i.year i.province_id,vce(ols)
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
*将结果存储到内存
est sto M4

*展示回归结果  可使用help esttab查看命令
local m "M1 M2 M3 M4"
local mt "hqed hqed hqed hqed" 
esttab `m',mtitle(`mt') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop (*.year *province_id) star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(基准回归)

*导出到csv
esttab M1 M2 M3 M4 using Peach2.csv, append mtitle(`mt') ///
nogap compress b(%6.3f) se(%9.3f) ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop (*.year *province_id) star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(基准回归)
unicode convertfile Peach2.csv Prach2_1.csv,dstencoding("gbk")replace 

*内生性问题检验
tab year, gen(dyear)
est clear
xtivreg2 $DV ($IV = L.$IV) $CV dyear*, ///
fe robust small cluster(province_id) first savefirst
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est store Second_stage
est restore _xtivreg2_$IV
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
estadd local Kleibergen_Paap_rk_LM "7.65"
estadd local P_value "[0.0057]"
estadd local Kleibergen_Paap_rk_wald_F "899.94"
est store First_stage_$IV

*系统GMM域差分GMM (内生性问题的一种方法)
*xtabond2 $DV L.$DV $IV $CV dyear*, 
*gmm(L.$DV $IV, lag(2,4) collapse) iv($CV dyear*) robust small or
*estadd local 省份固定效应 "是"
*estadd local 年份固定效应 "是"
*est sto SYSGMM
*xtabond2 $DV L.$DV $IV $CV dyear*, ///
*gmm(L.$DV $IV, lag(2,4) collapse) iv($CV dyear*) robust small or
*estadd local 省份固定效应 "是"
*estadd local 年份固定效应 "是"
*est sto DIFGMM

*展示内生性分析结果
local m "First_stage_$IV Second_stage"
local mt "（1）阶段DE (2)阶段HQED" 
esttab `m',mtitle(`mt') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 Kleibergen_Paap_rk_LM P_value ///
Kleibergen_Paap_rk_wald_F N, ///
fmt(%3s %3s %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %12.0f))  ///
drop (dyear*) star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(内生性问题检验)

*导出到csv
esttab First_stage_$IV Second_stage using Peach3.csv,mtitle(`mt') ///
nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 Kleibergen_Paap_rk_LM P_value ///
Kleibergen_Paap_rk_wald_F N, ///
fmt(%3s %3s %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %12.0f))  ///
drop (dyear*) star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(内生性问题检验)
unicode convertfile Peach3.csv Prach3_1.csv,dstencoding("gbk")replace 

*稳健性检验
**考虑解释变量滞后效应
gen L1_de = L.de
gen L2_de = L.L1_de
gen L3_de = L.L2_de

reghdfe $DV L1_de $CV, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto R1

reghdfe $DV L2_de $CV, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto R2

reghdfe $DV L3_de $CV, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto R3

**剔除新冠疫情影响的稳健性分析
reghdfe $DV $IV $CV if year != 2020, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto BR1

reghdfe $DV $IV $CV if year != 2020 & year != 2021, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto BR2

reghdfe $DV $IV $CV if year <= 2020, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto BR3

*输出稳健性检验结果
local m "R1 R2 R3"
local mt1 "hqed hqed hqed" 
esttab `m',mtitle(`mt1') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(考虑解释变量滞后效应的稳健性回归结果)

local m "BR1 BR2 BR3"
local mt2 "hqed hqed hqed" 
esttab `m',mtitle(`mt2') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(剔除新冠疫情影响的稳健性回归结果)

*稳健性检验结果导出到csv
esttab R1 R2 R3 using Peach4.csv,mtitle(`mt1') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(考虑解释变量滞后效应的稳健性回归结果)
unicode convertfile Peach4.csv Prach4_1.csv,dstencoding("gbk")replace 

esttab BR1 BR2 BR3 using Peach5.csv,mtitle(`mt2') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(剔除新冠疫情影响的稳健性回归结果)
unicode convertfile Peach5.csv Prach_15.csv,dstencoding("gbk")replace 


*异质性分析
**(1)不同地理区域：东，中，西
reghdfe $DV $IV $CV if area == 1, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto CR1

reghdfe $DV $IV $CV if area == 2, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto CR2

reghdfe $DV $IV $CV if area == 3, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto CR3

*(2)市场化水平：高，低
reghdfe $DV $IV $CV if marketization == 1, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto ER1

reghdfe $DV $IV $CV if marketization == 2, $OPT1
estadd local 省份固定效应 "是"
estadd local 年份固定效应 "是"
est sto ER2

*展示结果
local m "CR1 CR2 CR3"
local mt1 "hqed hqed hqed" 
esttab `m',mtitle(`mt1') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(不同地理区域的异质性分析)

local m "ER1 ER2"
local mt2 "hqed hqed" 
esttab `m',mtitle(`mt2') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(不同市场化水平的异质性分析)

*输出结果csv
esttab CR1 CR2 CR3 using Peach6.csv,mtitle(`mt1') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(不同地理区域的异质性分析)
unicode convertfile Peach6.csv Prach6_1.csv,dstencoding("gbk")replace 

esttab ER1 ER2 using Peach7.csv,mtitle(`mt2') nogap compress b(%6.3f) se(%9.3f)  ///
s(省份固定效应 年份固定效应 r2 r2_a N F,fmt(%3s %3s %9.3f %9.3f %12.0f %9.3f ))  ///
drop () star(* 0.1 ** 0.05 *** 0.001) order($IV $CV)  ///
title(不同市场化水平的异质性分析)
unicode convertfile Peach7.csv Prach7_1.csv,dstencoding("gbk")replace 

