with open('program.asm','r',encoding='utf-8') as file1:
    with open('program_without_comm.asm','w',encoding='utf-8') as file2:
        for line in file1.readlines():
            if line.lstrip(' ')[0] != '\n' and line.lstrip(' ')[0] != ';':
                file2.write(line)