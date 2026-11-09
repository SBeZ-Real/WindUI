local Calendar = {}
function Calendar.Leap(year) return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) end
function Calendar.Days(year, month)
    return ({31, Calendar.Leap(year) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[month]
end
function Calendar.Valid(value)
    return type(value) == "table" and type(value.Year) == "number" and value.Year % 1 == 0 and value.Year >= 1900 and value.Year <= 9999 and type(value.Month) == "number" and value.Month % 1 == 0 and value.Month >= 1 and value.Month <= 12 and type(value.Day) == "number" and value.Day % 1 == 0 and value.Day >= 1 and value.Day <= Calendar.Days(value.Year, value.Month)
end
function Calendar.Weekday(year, month, day)
    local offsets = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
    if month < 3 then year -= 1 end
    return (year + math.floor(year / 4) - math.floor(year / 100) + math.floor(year / 400) + offsets[month] + day) % 7
end
function Calendar.Compare(a, b) return a.Year * 10000 + a.Month * 100 + a.Day - (b.Year * 10000 + b.Month * 100 + b.Day) end
function Calendar.Time(value)
    return type(value) == "table" and type(value.Hour) == "number" and type(value.Minute) == "number" and value.Hour % 1 == 0 and value.Minute % 1 == 0 and value.Hour >= 0 and value.Hour <= 23 and value.Minute >= 0 and value.Minute <= 59
end
return Calendar
