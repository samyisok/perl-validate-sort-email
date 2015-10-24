# perl_find_sort_correct_email

App for validate and make domain statistic.


## Generate test email lists

Usage:
    
    #./perl-mail-gen.pl  

    Usage: ./perl-mail-gen.pl --emails_count 999
    Default: 45427
    Usage: ./perl-mail-gen.pl --files_count 1
    Default: 9
    Usage: ./perl-mail-gen.pl --prefix_file NAME
    Default "output_"

    or

    #./perl-mail-gen.pl  --emails_count 45000 --files_count 3 --prefix_file mails_


Output:

    #cat output_1.txt | head
    
    bunglevW@Agmail.ru
    ticklest;@?1mail.ru
    Melanesian:;@123.pro
    panted\j@123.pro
    strikerx'@_uncorrect.com
    parchmentX@yandex.ru
    RhodaB@123.pro
    imbalancel@DHbk.ru
    edictLZ@correct-b10.com
    spirally.]@Bgmail.ru


## Validate and Make Domain Report

Usage:

    #./perl-sort-mail.pl output_1.txt output_2.txt output_3.txt

output:
    
    In list email: 136281
    Start Job: 3
    Start Job: 2
    Start Job: 1
    Start Job: 0
    JobDone
    JobDone
    JobDone
    JobDone
    Totaly correct emails: 62223
    Totaly correct domains: 5350

 output File:

    #cat output_report.txt | tail

    xmail.ru = 93
    v123.pro = 93
    bmail.ru = 99
    vbk.ru = 104
    correct-b10.com = 6615
    bk.ru = 6624
    yandex.ru = 6626
    123.pro = 6631
    mail.ru = 6710
    gmail.ru = 6859
