#include <iostream>
#include "PREnableLogger.h"
//#include <log4cxx/logger.h>
//#include <log4cxx/basicconfigurator.h>
//#include <log4cxx/consoleappender.h>
//#include <log4cxx/simplelayout.h>

@implementation PREnableLogger

+ (void)enableLogger
{
//    log4cxx::ConsoleAppender *consoleAppender = new log4cxx::ConsoleAppender();
//    consoleAppender->setTarget("System.err");
//    consoleAppender->setLayout(log4cxx::LayoutPtr(new log4cxx::SimpleLayout()));
//    log4cxx::helpers::Pool p;
//    consoleAppender->activateOptions(p);
//
//    log4cxx::BasicConfigurator::configure(log4cxx::AppenderPtr(consoleAppender));
//    log4cxx::Logger::getRootLogger()->setLevel(log4cxx::Level::getDebug());
}

@end