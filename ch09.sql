# set session join_buffer_size=default
set session join_buffer_size=1024*8
# set session join_buffer_size=1024*64
# set session join_buffer_size=1024*256
# set session join_buffer_size=1024*1024*100
show variables like '%join%'
select *
from employees e ignore index (`PRIMARY`, ix_hiredate)
    inner join dept_emp de ignore index (ix_fromdate, ix_empno_fromdate)
        on de.emp_no=e.emp_no and de.from_date=e.hire_date
;

#######
set session optimizer_switch='prefer_ordering_index=ON';
show variables like 'optimizer_switch%';
select *
from employees e ignore index (ix_hiredate)
where e.hire_date between '1985-01-01' and '1985-02-01'
order by e.emp_no ;
select /*+ set_var(optimizer_switch='prefer_ordering_index=ON') */ *
from employees e
where e.hire_date between '1985-01-01' and '1985-02-01'
order by e.emp_no ;

##########

# 인덱스 머지
select * from employees e where e.first_name='Georgi' and e.hire_date between '1990-01-01' and '1990-01-31'
select /*+ index_merge(e ix_hiredate,ix_firstname) */ *
from employees e where e.first_name='Georgi' and e.hire_date between '1990-01-01' and '1990-12-31' ;
select count(*) from employees e where e.first_name='Georgi';  # 253
select count(*) from employees e where e.hire_date between '1990-01-01' and '1990-12-31';  # 25610

select * from employees e where e.first_name='Georgi' and e.emp_no between 10000 and 20000 ;
select /*+ index_merge(e primary,ix_firstname) */ * from employees e where e.first_name='Georgi' and e.emp_no between 10000 and 20000 ;
select /*+ index_merge(e ix_hiredate,ix_firstname) */ * from employees e where e.first_name='Georgi' and e.emp_no between 10000 and 20000 ;

###########


