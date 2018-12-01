file program
set disassembly-flavor intel
# дизассемблировать блоки кода
b _encrypt_text
run
# цикл пока счетчик команд меньше
# адреса метки fin
while $pc<_end
# показать текущую инструкцию
x/i $pc
# выполнить инструкцию
ni 
# показать регистры
info registers
end
c
quit