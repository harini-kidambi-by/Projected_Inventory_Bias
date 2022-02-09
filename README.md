# Bias in projected inventory computation

As a statistician, I am interested to know how accurate the projected inventory computations has been in LCT. To evaluate this, Bias is determined by comparing the projected inventory computation in the past and the actual on hand inventory.

I believe that there is very little bias in the current LCT computation and I want to test this hypothesis @ significance level of 5%. 

Null hypothesis, H0 : there is no difference between PI and On_hand (mean difference between the two is 0)
Alternate hypothesis, H1 : there is difference between PI and On_hand (mean difference between the two is not 0)

Test performed: Paired T-Test => I want to test differences between samples of the same group at different points in time

Data - 
Tenant : GSK Production
Period : Last 6 months
Sample size - Top 3000 nodes based on Revenue
Granularity - Daily, node inventory
![image](https://user-images.githubusercontent.com/72233116/153102700-15f96605-dbf4-4903-a6af-2544edcf446d.png)
