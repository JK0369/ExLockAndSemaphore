//
//  ViewController.swift
//  ExTest
//
//  Created by Jake.K on 2022/08/03.
//
import UIKit

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    self.runGoodZeroSemaphore()
  }
  
  // MARK: - NSLock
  // Wrong - lock()을 호출한 곳이 global()안의 스레드지만, unlock()을 한곳이 main이므로 unlock동작이 안됨
  func runWrongFirstNSLock() {
    let lock = NSLock()
    DispatchQueue.global().async {
      lock.lock()
    }
    
    print("wait for task A")
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      print("finish Task A")
      lock.unlock()
    }
    
    print("Call after task A is done")
  }
  
  // Wrong - global()로 선언해서 같은 큐이지만, DispatchQueue에는 여러개의 쓰레드가 동작하므로 lock할때와 unlock할때의 쓰레드가 다를 수 있음
  func runWrongSecondNSLock() {
    let lock = NSLock()
    DispatchQueue.global().async {
      lock.lock()
    }
    
    print("wait for task A")
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
      print("finish Task A")
      lock.unlock()
    }
    
    print("Call after task A is done")
  }
  
  // MARK: - Semaphore
  func runTwoSemaphore() {
    let semaphore = DispatchSemaphore(value: 2)
    
    (1...10).forEach { i in
      DispatchQueue.global().async() {
        semaphore.wait() //semaphore 감소
        print("Entry critcal section \(i)")
        sleep(1)
        print("Exit critcal section \(i)")
        semaphore.signal()
      }
    }
  }
  
  // Wrong - 세마포어는 main thread에서 부르게 되면 UI도 같이 동작 wait하므로 MainThread에서 wait 금지
  func runWrongFirstZeroSemaphore() {
    let semaphore = DispatchSemaphore(value: 0)
    
    print("wait for task A")
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
      print("finish Task A")
      semaphore.signal()
    }
    
    // semaphore가 0이라 task A 종료까지 block
    semaphore.wait()
    print("Call after task A is done")
  }
  
  // Good - DispatchQueue.global()를 사용하면 안에서 스레드를 새로 생성하므로, 다른 global queue의 스레드와 겹치지 않게 되어,
  // wait되어도 다른곳에서 global로 접근해도 wait하지 않고 사용이 가능
  func runGoodZeroSemaphore() {
    let semaphore = DispatchSemaphore(value: 0)
    
    print("wait for task A")
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
      print("finish Task A")
      semaphore.signal()
    }
    
    // semaphore가 0이라 task A 종료까지 block
    DispatchQueue.global().async {
      semaphore.wait()
      print("Call after task A is done")
    }
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
      print("Test - can call before task As done")
    }
  }
    
  func runBestBlockSemaphoreUsingThread() {
    let semaphore = DispatchSemaphore(value: 0)
    let thread = Thread {
      print("wait for task A")
      
      // wait 하는 곳의 스레드가 wait되므로 Thread로 따로 빼야 효율적
      // 만약 DispatchQueue.global()에서 wait하면 global()에 사용되는 스레드들이 wait되어서 비효율적
      semaphore.wait()
      print("Call after task A is done")
    }
    
    Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
      print("finish Task A")
      semaphore.signal()
    }
    
    thread.start()
    
    // semaphore와 연관없는 global() 큐
    DispatchQueue.global().async {
      print("바로 실행되어야함")
    }
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
      thread.cancel()
    }
  }
}
