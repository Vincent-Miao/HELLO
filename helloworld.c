#include<stdio.h>
int sum(int a , int b){
    return a+b;
}
int main(){
    int a  = 1;
    int b = 2;
    printf("%d\n" , sum(a , b));
    return 0;
}