use mysql ;
use employees ;
show tables like '%stats' ;

select * from employees ;
select * from salaries ;

select * from mysql.innodb_index_stats ;
select * from mysql.innodb_table_stats ;

select * from mysql.innodb_index_stats t where t.table_name='salaries' ;
select * from mysql.innodb_table_stats t where t.table_name='salaries' ;

# create table salaries (
#     emp_no    int  not null,
#     salary    int  not null,
#     from_date date not null,
#     to_date   date not null,
#     primary key (emp_no, from_date)
# ) collate = utf8mb4_general_ci;
# create index ix_salary on salaries (salary);

alter table employees.employees stats_persistent =1;
select * from mysql.innodb_index_stats t where t.database_name='employees' and t.table_name='employees' ;
select * from mysql.innodb_table_stats t where t.database_name='employees' and t.table_name='employees' ;

select * from mysql.innodb_table_stats ;
analyze table employees.employees ;
select now(), @@global.time_zone, @@session.time_zone ;

######

analyze table employees update histogram on birth_date ;
analyze table salaries update histogram on salary, emp_no ;
analyze table employees drop histogram on birth_date ;
analyze table salaries drop histogram on salary, emp_no ;
select * from information_schema.COLUMN_STATISTICS where SCHEMA_NAME='employees' and TABLE_NAME in ('employees','salaries') ;

select /*+ join_order(e,s) */ *
from salaries s join employees e on e.emp_no=s.emp_no
where s.salary between 40000 and 70000 and e.birth_date between '1953-01-01' and '1953-01-02' and e.gender='M' ;
select /*+ join_order(s,e) */ *
from salaries s join employees e on e.emp_no=s.emp_no
where s.salary between 40000 and 70000 and e.birth_date between '1953-01-01' and '1953-01-02' and e.gender='M' ;
# create index salaries_salary_emp_no_index on salaries (salary, emp_no) ;
# create index salaries_emp_no_salary_index on salaries (emp_no, salary) ;
# drop index salaries_salary_emp_no_index on salaries ;
# drop index salaries_emp_no_salary_index on salaries ;

#######

select * from mysql.server_cost ;
select * from mysql.engine_cost ;

######

explain analyze
select e.hire_date, avg(s.salary) avg_salary
from employees e
    join salaries s on s.emp_no=e.emp_no
        and s.salary>50000
        and s.from_date<='1990-01-01'
        and s.to_date>'1990-01-01'
where e.first_name='Matt'
group by e.hire_date ;

explain
select ( (select count(*) from employees e) + (select count(*) from departments d) ) as total_count ;

#######

select emp_no from employees e1 limit 10 ;
select emp_no from employees e1 ;
select emp_no from employees e1 use index (`PRIMARY`) ;

# DERIVED 디라이브드 파생된
select * from (
    (select emp_no from employees e1 limit 10) union all
    (select emp_no from employees e2 limit 10) union all
    (select emp_no from employees e3 limit 10) union all
    (select emp_no from employees e4 limit 10)
) tb ;

#########
select *
from ( select de.emp_no from dept_emp de group by de.emp_no) tb,
     employees e
where e.emp_no=tb.emp_no ;

select *
from ( select de.emp_no, de.to_date from dept_emp de group by de.emp_no, de.to_date) tb,
     employees e
where e.emp_no=tb.emp_no ;

########

# 파티션 테이블에 대한 실행계획

create table employees_2 (
    emp_no int not null,
    birth_date date not null,
    first_name varchar(14) not null,
    last_name varchar(16) not null,
    gender enum('M','F') not null,
    hire_date date not null,
    primary key (emp_no, hire_date)
) partition by range columns (hire_date)
(
    partition p1986_1990 values less than ('1990-01-01'),
    partition p1991_1995 values less than ('1996-01-01'),
    partition p1996_2000 values less than ('2000-01-01'),
    partition p2001_2005 values less than ('2006-01-01')
);
insert into employees_2 select * from employees ;

select
(select count(*) from employees_2),
(select count(*) from employees) ;

# 파티션 프루닝 pruning
select * from employees_2 e where hire_date between '1999-11-15' and '2000-01-15' ;

#######

# 실행계획 빠른순서
# system : innodb 아닌 엔진에서 const
# const : 유니크 인덱스 사용해서 1개 레코드만 검색이 확실한 경우
# eq_ref : 조인 유니크 동등 비교
# ref : 동등 비교
# fulltext : 전문검색 인덱스 사용
# ref_or_null : ref 에 is null 추가
# unique_subquery : in 서브쿼리
# index_subquery : in 서브쿼리
# range : 인덱스 부분 사용
# index_merge : 인덱스 2개 사용후 집합처리
# index : 인덱스 풀스캔
# ALL : 테이블 풀스캔

######

select * from dept_emp de, employees e
where e.emp_no=de.emp_no and de.dept_no='d005' ;

#######

# fulltext 가능한 경우에는 대부분 우선시 사용된다. 그러므로 주의
select * from employee_name e
where 1=1
# and emp_no=10001
and emp_no between 10001 and 10005
# and match(first_name,last_name) against('Facello' IN boolean mode )
;

########

# or 로 묶인 조건 2개가 각각 primary ix_firstname 인덱스 사용이 가능하므로
# 인덱스 머지를 사용함
select * from employees e
where e.emp_no between 10001 and 11000
   or e.first_name='Smith' ;

# type=index 는 인덱스 풀스캔을 의미한다
select dept_name from departments order by dept_name desc limit 10 ;

##############

# 실행 계획의 type 컬럼이 index_merge 가 아닌 경우에는
# 반드시 테이블 하나당 하나의 인덱스만 이용할 수 있다

# key_len 컬럼은 인덱스의 길이가 아니라 다중 컬럼 인덱스 중 사용된 바이트 수
# dept_emp 테이블 primary key (dept_no, emp_no)
# emp_no    int     not null, => 4 바이트
# dept_no   char(4) not null, => 16 바이트
select * from dept_emp de where de.dept_no='d005' ;  # key_len=16
select * from dept_emp de where de.dept_no='d005' and de.emp_no=10001 ;  # key_len=20

#######
;

# Using filesort
# 정렬용 메모리 버퍼에 복사해서 정렬하는 의미
# 중요한 내용이므로 11장 order by 에서 다시 다룬다

# 카테시안 조인: 조인 조건이 없는 조인, 항상 조인 버퍼를 사용함
select * from dept_emp de, employees e
where de.from_date>'2005-01-01' and e.emp_no<10904 ;

#############

# 485 페이지 부터 ~

# create index ix_empno_gender on employees (emp_no, gender) ;
# drop index ix_empno_gender on employees ;

select e.emp_no, e.gender
# select *
from employees e use index (ix_empno_gender)
# from employees e
where 1
and e.emp_no between 10001 and 11000
and e.gender='F' ;

select * from employees e limit 0 ;