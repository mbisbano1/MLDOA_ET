%Michael Bisbano
%POSIX1970_TO_DAY
    %this function takes in a 
    %   'PingTimeStamp' which is the number of seconds since 1970, 
    %and converts it to 
    %   'numSecondsToday' which is the number of seconds since the
    %    start of that day. 
function numSecondsToday = POSIX1970_TO_DAY(PingTimeStamp)
    TimeOfPing = datetime(PingTimeStamp, 'convertfrom', 'posixtime');
    TimeBeginOfDay = datetime(year(TimeOfPing), month(TimeOfPing), day(TimeOfPing));
    dt = time(between(TimeBeginOfDay, TimeOfPing));
    numSecondsToday = 60*(60*hours(dt)+minutes(dt))+seconds(dt);
    return
end