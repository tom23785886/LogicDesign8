#include <iostream>

using namespace std;
char music[1000];
int notecount;
int main()
{
    string cmd;
    notecount=0;
    while(cin>>cmd)
    {
        if(cmd=="print")
        {
            for(int i=0;i<notecount;i++)
            {
                cout<<"12'd"<<i<<": toneL = ";
                if(isdigit(music[i]))
                {
                    if((char)(music[i]+50)=='h') cout<<"`ha";
                    else if((char)(music[i]+50)=='i') cout<<"`hb";
                    else cout<<"`h"<<(char)(music[i]+50);
                }
                else
                {
                    if(music[i]=='s') cout<<"`sil";
                    else cout<<"`"<<music[i];
                }
                cout<<"; ";
                if((i+5)%4==0) cout<<endl;
                if((i+1)%16==0)cout<<endl;
            }
        }
        else if(cmd=="input")
        {
            while(1)
            {
                int note;
                cout<<"Please enter the note:";
                cin>>note;
                if(note==100) break;
                int time;
                cout<<"Please enter the time:"<<endl;
                cin>>time;
                if(note==1)
                {
                 for(int j=0;j<time;j++) music[notecount++]='c';
                }
                else if(note==2)
                {
                   for(int j=0;j<time;j++) music[notecount++]='d';
                }
                else if(note==3)
                {
                   for(int j=0;j<time;j++) music[notecount++]='e';
                }
                else if(note==4)
                {
                   for(int j=0;j<time;j++) music[notecount++]='f';
                }
                else if(note==5)
                {
                   for(int j=0;j<time;j++) music[notecount++]='g';
                }
                else if(note==6)
                {
                   for(int j=0;j<time;j++) music[notecount++]='a';
                }
                else if(note==7)
                {
                   for(int j=0;j<time;j++) music[notecount++]='b';
                }
                else if(note==8)
                {
                    for(int j=0;j<time;j++) music[notecount++]='l';
                }
                else if(note==9)
                {
                    for(int j=0;j<time;j++) music[notecount++]='k';
                }
                else if(note==10)
                {
                    for(int j=0;j<time;j++) music[notecount++]='m';
                }
                else if(note==11)
                {
                    for(int j=0;j<time;j++) music[notecount++]='n';
                }
                else if(note==0)
                {
                   for(int j=0;j<time;j++) music[notecount++]='s';
                }
                else if(note==-1)
                {
                   for(int j=0;j<time;j++) music[notecount++]='1';
                }
                else if(note==-2)
                {
                   for(int j=0;j<time;j++) music[notecount++]='2';
                }
                else if(note==-3)
                {
                   for(int j=0;j<time;j++) music[notecount++]='3';
                }
                else if(note==-4)
                {
                   for(int j=0;j<time;j++) music[notecount++]='4';
                }
                else if(note==-5)
                {
                   for(int j=0;j<time;j++) music[notecount++]='5';
                }
                else if(note==-6)
                {
                   for(int j=0;j<time;j++) music[notecount++]='6';
                }
                else if(note==-7)
                {
                   for(int j=0;j<time;j++) music[notecount++]='7';
                }
            }


        }
    }
    return 0;
}
