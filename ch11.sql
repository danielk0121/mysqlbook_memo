# 2권의 시작, 11장 부터

####

# 2개 이상 컬럼을 인덱스로 잡을때, between 을 사용하는 것과, in 을 사용하는 것으로 실행계획 차이가 난다

# 331603
# table dept_emp => primary key (dept_no, emp_no)
select count(*) from dept_emp ;

# type=range, key=primary, rows=165571 => dept_no 에 대해 range 스캔을 모두 해야됨
select * from dept_emp d use index (`PRIMARY`) where d.dept_no between 'd003' and 'd005' and emp_no=10001;

# type=range, key=primary, rows=3 => dept_no 와 emp_no 조합이 3가지 조건에 대해서만 스캔 하면 됨
select * from dept_emp d use index (`PRIMARY`) where d.dept_no in ('d003','d004','d005') and emp_no=10001;

####

# salary 컬럼을 가공한 후 다른 상숫값과 비교한다면 이 쿼리는 인덱스를 적절히 활용 못한다
select salary from salaries s where s.salary*10 > 150000;  -- type=index, rows=2838426, 인덱스 풀스캔, 컬럼을 가공해서 인덱스 안됨
select salary from salaries s where s.salary > 150000/10;  -- type=range, rows=1419213, 인덱스 레인지, 식을 변경해서 인덱스 사용 가능 하도록 수정

# 컬럼과 날짜를 비교할때도 컬럼에 함수를 적용하지 말고, 비교 상수에 함수를 적용해서 인덱스를 활용한다
select count(*) from employees e where date_add(e.hire_date, interval 1 year) > '2011-07-23' ; -- 인덱스 풀스캔
select count(*) from employees e where e.hire_date > date_sub('2011-07-23', interval 1 year) ; -- 인덱스 레인지

####
;

# limit m,n 에서 m 값이 커지면 m 값 만큼 레코드를 읽은 후 개수 제한을 해야 하므로 느릴 수 있다
# where 조건으로 미리 개수를 제한 후 조회 하면 더 적은 레코드를 읽을 수 있다
# 즉, limit 조회로 느려질 수 있는 쿼리를 인덱스 레인지 스캔으로 변경해서 사용한다 !
select count(*) from employees e ; -- 300 024
select * from employees e limit 200000, 2 ; -- execution: 53 ms, fetching: 10 ms
select * from employees e where e.emp_no > 200000 limit 2 ; -- execution: 6 ms, fetching: 9 ms

####
;

# with rollup 하면 소계를 추가해준다
select count(*) from dept_emp d ; -- 331 603
select d.dept_no, count(*) from dept_emp d group by d.dept_no with rollup ;

# with rollup 소계에서 grouping() 함수를 통해 소계에 표시되는 NULL 에 이름을 지정 할 수 있다
select * from (
select
    if(grouping(first_name), 'All_first_name', first_name) as first_name,
    if(grouping(last_name), 'All_last_name', last_name) as last_name,
    count(*)
from employees e group by e.first_name, e.last_name with rollup
) t where t.last_name='All_last_name' ;

# CTE = common table expression, with 절로 만드는 임시 테이블

# insert 테스트를 위한 일자별 통계 테이블 생성
create table daily_statistic (
    target_date date not null,
    stat_name varchar(10) not null,
    stat_value bigint not null default 0,
    primary key (target_date, stat_name)
) ;
# insert 테스트를 위한 log 테이블 생성
create table access_log(id bigint not null auto_increment, visited_at varchar(10), log varchar(200), primary key (id));
select * from access_log ;
select * from daily_statistic ;

# insert on duplicate key update, 별칭으로 update 시점의 레코드 접근이 가능하다
insert into daily_statistic
    select target_date, stat_name, stat_value
    from (
        select date(visited_at) target_date, 'visit' stat_name, count(*) stat_value
        from access_log
        group by date(visited_at)
    ) as stat
on duplicate key update daily_statistic.stat_value = daily_statistic.stat_value + stat.stat_value
;

# insert values 에서 튜플을 as 로 별칭 부여 해서 사용 가능하다
select * from daily_statistic ;
insert into daily_statistic (target_date, stat_name, stat_value)
values ('2020-09-01', 'visit', 1), ('2020-09-01', 'visit', 2) as new /* new 라는 이름으로 별칭 부여 */
on duplicate key update daily_statistic.stat_value = daily_statistic.stat_value + new.stat_value ;

#


